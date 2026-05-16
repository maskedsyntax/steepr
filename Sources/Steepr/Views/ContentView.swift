import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var teaStore: TeaStore
    @EnvironmentObject private var brewSessionStore: BrewSessionStore
    @StateObject private var timerCoordinator = TimerCoordinator()
    @State private var selectedTab = 0
    @State private var libraryPath = NavigationPath()
    @State private var showingCompletionSheet = false
    @State private var recordedCompletedSessions: Set<UUID> = []

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
        .tint(TeaColorSlot.green.color)
        .sheet(isPresented: Binding(
            get: { !teaStore.preferences.onboardingComplete },
            set: { if !$0 { teaStore.setOnboardingComplete(true) } }
        )) {
            OnboardingView()
                .interactiveDismissDisabled()
        }
        .task {
            timerCoordinator.restoreIfNeeded(preferences: teaStore.preferences)
        }
        .onChange(of: timerCoordinator.state) { _, state in
            guard state == .completed else { return }
            recordCompletionIfNeeded()
            showingCompletionSheet = selectedTab != 0
        }
        .onChange(of: selectedTab) { _, tab in
            if tab == 0 {
                showingCompletionSheet = false
            }
        }
        .sheet(isPresented: $showingCompletionSheet) {
            TimerCompleteSheet(timerCoordinator: timerCoordinator)
                .environmentObject(teaStore)
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
            durationSeconds: timerCoordinator.durationSeconds
        )
    }
}

private struct TimerCompleteSheet: View {
    @EnvironmentObject private var teaStore: TeaStore
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

                HStack(spacing: 12) {
                    Button("Brew again") {
                        timerCoordinator.brewAgain(preferences: teaStore.preferences)
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
