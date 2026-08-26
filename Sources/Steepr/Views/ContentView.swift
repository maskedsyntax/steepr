import StoreKit
import SwiftUI

/// Completed brews required before the App Store review prompt is requested.
/// Deliberately not 7, which is already claimed by the Pro milestone prompt in `BrewView`.
private let reviewPromptBrewThreshold = 3

struct ContentView: View {
    @EnvironmentObject private var teaStore: TeaStore
    @EnvironmentObject private var brewSessionStore: BrewSessionStore
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.requestReview) private var requestReview
    @StateObject private var timerCoordinator = TimerCoordinator()
    @State private var selectedTab = 0
    @State private var libraryPath = NavigationPath()
    @State private var showingCompletionSheet = false
    @State private var recordedCompletedSessions: Set<UUID> = []

    private var isImmersiveSession: Bool {
        selectedTab == 0 && (timerCoordinator.state == .running || timerCoordinator.state == .paused || timerCoordinator.state == .completed)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            BrewView(
                timerCoordinator: timerCoordinator,
                selectedTab: $selectedTab
            )
            .tabItem {
                Label("Brew", systemImage: "cup.and.saucer.fill")
            }
            .tag(0)

            LibraryView(
                timerCoordinator: timerCoordinator,
                selectedTab: $selectedTab,
                path: $libraryPath
            )
            .tabItem {
                Label("Library", systemImage: "books.vertical.fill")
            }
            .tag(1)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(2)
        }
        .tint(SteeprPalette.accent)
        #if os(iOS)
        .toolbarBackground(SteeprPalette.background, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbar(isImmersiveSession ? .hidden : .visible, for: .tabBar)
        #endif
        .task {
            timerCoordinator.restoreIfNeeded(preferences: teaStore.preferences)
        }
        .onChange(of: timerCoordinator.state) { _, state in
            guard state == .completed else { return }
            recordCompletionIfNeeded()
            showingCompletionSheet = selectedTab != 0
            requestReviewIfEarned()
        }
        .onChange(of: selectedTab) { _, tab in
            if tab == 0 {
                showingCompletionSheet = false
            }
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            timerCoordinator.reloadFromSharedTimer(preferences: teaStore.preferences)
            if timerCoordinator.activeTea != nil {
                selectedTab = 0
            }
        }
        .onOpenURL { url in
            handleWidgetURL(url)
        }
        .sheet(isPresented: $showingCompletionSheet) {
            TimerCompleteSheet(timerCoordinator: timerCoordinator)
                .environmentObject(teaStore)
        }
        .onboardingPresentation(isPresented: Binding(
            get: { !teaStore.preferences.onboardingComplete },
            set: { _ in }
        )) {
            OnboardingView()
                .environmentObject(teaStore)
                .environmentObject(brewSessionStore)
        }
    }

    private func recordCompletionIfNeeded() {
        guard
            let tea = timerCoordinator.activeTea,
            let startedAt = timerCoordinator.startedAt,
            !recordedCompletedSessions.contains(timerCoordinator.currentSessionID)
        else {
            return
        }

        recordedCompletedSessions.insert(timerCoordinator.currentSessionID)
        brewSessionStore.recordCompletion(
            sessionID: timerCoordinator.currentSessionID,
            tea: tea,
            startedAt: startedAt,
            durationSeconds: timerCoordinator.durationSeconds,
            infusionNumber: timerCoordinator.infusionNumber
        )
    }

    /// Asks for an App Store review once the user has completed enough brews to have an opinion.
    /// The flag is persisted so the prompt is only ever requested a single time; Apple applies
    /// its own rate limiting on top and may show nothing at all.
    private func requestReviewIfEarned() {
        guard
            !teaStore.preferences.hasRequestedReview,
            brewSessionStore.completedCount >= reviewPromptBrewThreshold
        else {
            return
        }

        teaStore.markReviewRequested()

        Task {
            // Let the completion sheet and its haptic settle before the system prompt lands.
            try? await Task.sleep(for: .seconds(2))
            requestReview()
        }
    }

    private func handleWidgetURL(_ url: URL) {
        guard url.scheme == "steepr" else { return }

        switch url.host {
        case "quick-brew":
            handleQuickBrewURL(url)
        case "timer":
            handleTimerControlURL(url)
        default:
            return
        }
    }

    private func handleQuickBrewURL(_ url: URL) {

        let idString = url.pathComponents.dropFirst().first
        guard
            let idString,
            let teaID = UUID(uuidString: idString),
            let tea = teaStore.tea(with: teaID)
        else {
            selectedTab = 1
            return
        }

        selectedTab = 0
        timerCoordinator.start(tea, preferences: teaStore.preferences)
    }

    private func handleTimerControlURL(_ url: URL) {
        guard let action = url.pathComponents.dropFirst().first else { return }

        timerCoordinator.reloadFromSharedTimer(preferences: teaStore.preferences)
        selectedTab = 0

        switch action {
        case "pause":
            timerCoordinator.pause()
        case "stop":
            timerCoordinator.cancel()
        default:
            return
        }
    }
}

private extension View {
    @ViewBuilder
    func onboardingPresentation<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        #if os(macOS)
        sheet(isPresented: isPresented, content: content)
        #else
        fullScreenCover(isPresented: isPresented, content: content)
        #endif
    }
}

private struct TimerCompleteSheet: View {
    @EnvironmentObject private var teaStore: TeaStore
    @EnvironmentObject private var brewSessionStore: BrewSessionStore
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var timerCoordinator: TimerCoordinator

    var body: some View {
        VStack(spacing: 18) {
            if let tea = timerCoordinator.activeTea {
                TeaIconView(tea: tea, size: 72)
                Text("Your \(tea.name) is ready")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                Text("Steeped for \(formatDuration(timerCoordinator.durationSeconds)).")
                    .foregroundStyle(.secondary)
                Text("Infusion \(timerCoordinator.infusionNumber) complete")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)

                if tea.supportsGuidedReSteep, teaStore.preferences.proPurchased {
                    Text("Next guided steep: \(formatDuration(tea.steepSeconds(forInfusion: timerCoordinator.infusionNumber + 1, proPurchased: true))).")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 12) {
                    Button(teaStore.preferences.proPurchased && tea.supportsGuidedReSteep ? "Start infusion \(timerCoordinator.infusionNumber + 1)" : "Re-steep") {
                        timerCoordinator.reSteep(preferences: teaStore.preferences)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Done") {
                        timerCoordinator.done()
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding()
    }
}
