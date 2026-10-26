import SwiftUI
import UserNotifications

#if os(iOS)
import UIKit
#endif

struct BrewView: View {
    @EnvironmentObject private var teaStore: TeaStore
    @EnvironmentObject private var brewSessionStore: BrewSessionStore
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.openURL) private var openURL
    @ObservedObject var timerCoordinator: TimerCoordinator
    @Binding var selectedTab: Int
    @State private var notificationsDenied = false
    @State private var showingPaywall = false
    @State private var showingCancelConfirmation = false

    private var gridColumns: [GridItem] {
        if dynamicTypeSize.isAccessibilitySize {
            return [GridItem(.flexible())]
        }
        return [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
    }

    private var isActiveSession: Bool {
        switch timerCoordinator.state {
        case .running, .paused, .completed:
            return true
        case .idle:
            return false
        }
    }

    /// Up to three distinct completed teas that still exist in the current library.
    private var repeatableRecentBrews: [(session: BrewSession, tea: Tea)] {
        brewSessionStore.recentDistinctCompletedSessions(
            availableTeaIDs: Set(teaStore.teas.map(\.id))
        ).compactMap { session in
            teaStore.tea(with: session.teaID).map { (session, $0) }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SteeprPalette.background
                    .ignoresSafeArea()

                Group {
                    if isActiveSession {
                        activeSessionChrome
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 24) {
                                if notificationsDenied {
                                    notificationDeniedBanner
                                }
                                idleContent
                            }
                            .padding()
                            .frame(maxWidth: 640, alignment: .leading)
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .navigationTitle(isActiveSession ? "" : "Brew")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(isActiveSession ? .hidden : .automatic, for: .navigationBar)
            #endif
            .task {
                await refreshNotificationStatus()
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView(trigger: "Guided infusions")
            }
            .confirmationDialog(
                "Cancel timer?",
                isPresented: $showingCancelConfirmation,
                titleVisibility: .visible
            ) {
                Button("Cancel Timer", role: .destructive) {
                    cancelTimer()
                }
                Button("Keep Timer", role: .cancel) { }
            } message: {
                Text("The current brew timer will stop.")
            }
        }
    }

    // MARK: - Active session shell

    private var activeSessionChrome: some View {
        VStack(spacing: 0) {
            if notificationsDenied {
                notificationDeniedBanner
                    .padding(.horizontal)
                    .padding(.top, 8)
            }

            switch timerCoordinator.state {
            case .running, .paused:
                activeTimerContent
            case .completed:
                completedContent
            case .idle:
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Idle

    private var notificationDeniedBanner: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "bell.slash.fill")
                .foregroundStyle(SteeprPalette.inkSecondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text("Notifications are off")
                    .font(.headline)
                    .foregroundStyle(SteeprPalette.ink)
                Text("Enable notifications so Steepr can alert you when your tea is ready.")
                    .font(.footnote)
                    .foregroundStyle(SteeprPalette.inkSecondary)
            }

            Spacer()

            Button("Settings") {
                #if os(iOS)
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
                #endif
            }
            .buttonStyle(.bordered)
        }
        .padding(12)
        .background(SteeprPalette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(SteeprPalette.controlStroke, lineWidth: 1)
        }
    }

    private var idleContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("What are you brewing?")
                    .font(.largeTitle.bold())
                    .foregroundStyle(SteeprPalette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(teaStore.favoriteTeas.isEmpty
                     ? "Start a Quick Pick or browse the full library."
                     : "Start a favorite tea or browse the full library.")
                    .font(.subheadline)
                    .foregroundStyle(SteeprPalette.inkSecondary)
            }

            if !brewSessionStore.sessions.isEmpty {
                recentBrewSection
            }

            if teaStore.favoriteTeas.isEmpty {
                Text("Quick Picks")
                    .font(.title3.bold())
                    .foregroundStyle(SteeprPalette.ink)

                LazyVGrid(columns: gridColumns, spacing: 12) {
                    ForEach(teaStore.quickPickTeas) { tea in
                        Button {
                            timerCoordinator.start(tea, preferences: teaStore.preferences)
                        } label: {
                            FavoriteTeaCard(tea: tea, useCelsius: teaStore.preferences.useCelsius)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Start \(tea.name) timer")
                    }
                }

                Button {
                    selectedTab = 1
                } label: {
                    Label("Browse all teas", systemImage: "books.vertical")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(SteeprPalette.accent)
                .controlSize(.large)
            } else {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Favorites")
                            .font(.title3.bold())
                            .foregroundStyle(SteeprPalette.ink)

                        NavigationLink("Edit") {
                            ManageFavoritesView()
                        }
                        .font(.subheadline.weight(.semibold))
                        .accessibilityLabel("Edit favorites")
                    }
                } else {
                    HStack {
                        Text("Favorites")
                            .font(.title3.bold())
                            .foregroundStyle(SteeprPalette.ink)

                        Spacer()

                        NavigationLink("Edit") {
                            ManageFavoritesView()
                        }
                        .font(.subheadline.weight(.semibold))
                        .accessibilityLabel("Edit favorites")
                    }
                }

                LazyVGrid(columns: gridColumns, spacing: 12) {
                    ForEach(teaStore.favoriteTeas) { tea in
                        Button {
                            timerCoordinator.start(tea, preferences: teaStore.preferences)
                        } label: {
                            FavoriteTeaCard(tea: tea, useCelsius: teaStore.preferences.useCelsius)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Start \(tea.name) timer")
                    }
                }

                Button {
                    selectedTab = 1
                } label: {
                    Label("Browse all teas", systemImage: "books.vertical")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(SteeprPalette.accent)
                .controlSize(.large)
            }
        }
    }

    private var recentBrewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Recent Brews")
                        .font(.title3.bold())
                        .foregroundStyle(SteeprPalette.ink)

                    NavigationLink("View All") {
                        BrewHistoryView()
                    }
                    .font(.subheadline.weight(.semibold))
                    .accessibilityLabel("View brew history")
                }
            } else {
                HStack {
                    Text("Recent Brews")
                        .font(.title3.bold())
                        .foregroundStyle(SteeprPalette.ink)

                    Spacer()

                    NavigationLink("View All") {
                        BrewHistoryView()
                    }
                    .font(.subheadline.weight(.semibold))
                    .accessibilityLabel("View brew history")
                }
            }

            if repeatableRecentBrews.isEmpty {
                Text("No completed brews yet.")
                    .font(.subheadline)
                    .foregroundStyle(SteeprPalette.inkSecondary)
            } else {
                VStack(spacing: 10) {
                    ForEach(repeatableRecentBrews, id: \.tea.id) { recentBrew in
                        RecentBrewRow(session: recentBrew.session, tea: recentBrew.tea) {
                            timerCoordinator.start(recentBrew.tea, preferences: teaStore.preferences)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Active timer (screenshot-style)

    private var activeTimerContent: some View {
        GeometryReader { geometry in
            let isCompact = geometry.size.height < 700

            VStack(spacing: 0) {
                Spacer(minLength: isCompact ? 8 : 16)

                if let tea = timerCoordinator.activeTea {
                    ActiveSessionHeader(
                        tea: tea,
                        statusLine: statusLine(for: tea)
                    )
                    .padding(.horizontal, 24)

                    Spacer(minLength: isCompact ? 16 : 28)

                    TimerRingView(
                        progress: timerCoordinator.progress,
                        timeText: timerCoordinator.formattedTime(),
                        statusText: timerCoordinator.state == .paused ? "Paused" : "Steeping",
                        color: tea.colorSlot.color
                    )
                    .frame(maxWidth: min(geometry.size.width - 48, isCompact ? 280 : 320))
                    .frame(maxWidth: .infinity)
                    .accessibilityAction(named: timerCoordinator.state == .running ? "Pause timer" : "Resume timer") {
                        togglePause()
                    }

                    Spacer(minLength: isCompact ? 16 : 28)

                    HStack(spacing: 12) {
                        BrewMetaCard(
                            icon: "thermometer.medium",
                            iconColor: SteeprPalette.temperature,
                            title: formatTemperature(tea.temperatureCelsius, useCelsius: teaStore.preferences.useCelsius),
                            subtitle: "Water temp"
                        )

                        BrewMetaCard(
                            icon: "leaf.fill",
                            iconColor: tea.colorSlot.color,
                            title: tea.tasteProfile,
                            subtitle: "Taste profile"
                        )
                    }
                    .padding(.horizontal, 20)

                    Spacer(minLength: isCompact ? 20 : 32)

                    SessionControlBar(
                        isRunning: timerCoordinator.state == .running,
                        onCancel: {
                            showingCancelConfirmation = true
                        },
                        onTogglePause: togglePause,
                        onFinishEarly: {
                            timerCoordinator.skip()
                        }
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, isCompact ? 12 : 24)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .frame(maxWidth: 640)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Completed

    private var completedContent: some View {
        ScrollView {
            if let tea = timerCoordinator.activeTea {
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(tea.colorSlot.color.opacity(0.14))
                            .frame(width: 96, height: 96)
                        Image(systemName: "bell.fill")
                            .font(.system(size: 36, weight: .medium))
                            .foregroundStyle(tea.colorSlot.color)
                    }

                    VStack(spacing: 8) {
                        Text("Done!")
                            .font(.largeTitle.bold())
                            .foregroundStyle(SteeprPalette.ink)

                        Text("Your \(tea.name) is ready.")
                            .font(.title3)
                            .foregroundStyle(SteeprPalette.inkSecondary)
                            .multilineTextAlignment(.center)

                        Text("Infusion \(timerCoordinator.infusionNumber) complete")
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(SteeprPalette.accent)
                    }

                    reSteepSequenceHint(for: tea)

                    BrewJournalPrompt(
                        sessionID: timerCoordinator.currentSessionID,
                        dismissAfterSave: false,
                        context: .completion
                    )

                    if shouldShowMilestonePrompt {
                        Button {
                            teaStore.markBrewMilestoneProPromptSeen()
                            showingPaywall = true
                        } label: {
                            Label("Unlock full tea journal", systemImage: "sparkles")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(SteeprPalette.accent)
                        .frame(maxWidth: 420)
                    }

                    HStack(spacing: 28) {
                        SessionControlButton(
                            systemImage: "checkmark",
                            label: "Done",
                            style: .secondary
                        ) {
                            timerCoordinator.done()
                        }

                        SessionControlButton(
                            systemImage: "arrow.clockwise",
                            label: nextInfusionTitle(for: tea),
                            style: .primary
                        ) {
                            timerCoordinator.reSteep(preferences: teaStore.preferences)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 28)
            }
        }
        .frame(maxWidth: 640)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private func statusLine(for tea: Tea) -> String {
        let time = timerCoordinator.formattedTime()
        switch timerCoordinator.state {
        case .paused:
            return "Paused · \(time) remaining"
        case .running:
            return "Steeping · \(time) remaining"
        default:
            return tea.name
        }
    }

    private func togglePause() {
        if timerCoordinator.state == .running {
            timerCoordinator.pause()
        } else {
            timerCoordinator.resume(preferences: teaStore.preferences)
        }
    }

    private func cancelTimer() {
        recordCancellationIfNeeded()
        timerCoordinator.cancel()
    }

    @ViewBuilder
    private func reSteepSequenceHint(for tea: Tea) -> some View {
        if tea.supportsGuidedReSteep {
            if teaStore.preferences.proPurchased {
                Text("Next guided steep: \(formatDuration(nextInfusionSeconds(for: tea))).")
                    .font(.footnote)
                    .foregroundStyle(SteeprPalette.inkSecondary)
            } else {
                Button {
                    showingPaywall = true
                } label: {
                    Label("Unlock guided infusion timing", systemImage: "sparkles")
                }
                .buttonStyle(.bordered)
                .tint(SteeprPalette.accent)
            }
        }
    }

    private func nextInfusionTitle(for tea: Tea) -> String {
        if teaStore.preferences.proPurchased, tea.supportsGuidedReSteep {
            return "Infusion \(timerCoordinator.infusionNumber + 1)"
        }
        return "Re-steep"
    }

    private func nextInfusionSeconds(for tea: Tea) -> Int {
        tea.steepSeconds(
            forInfusion: timerCoordinator.infusionNumber + 1,
            proPurchased: teaStore.preferences.proPurchased
        )
    }

    private var shouldShowMilestonePrompt: Bool {
        guard
            !teaStore.preferences.proPurchased,
            !teaStore.preferences.hasSeenBrewMilestoneProPrompt
        else {
            return false
        }

        let completedBrews = brewSessionStore.sessions.filter { $0.completedAt != nil }.count
        return completedBrews >= 7
    }

    private func recordCancellationIfNeeded() {
        guard
            let tea = timerCoordinator.activeTea,
            let startedAt = timerCoordinator.startedAt
        else {
            return
        }

        let elapsedSeconds = max(0, timerCoordinator.durationSeconds - timerCoordinator.secondsRemaining)
        brewSessionStore.recordCancellation(
            sessionID: timerCoordinator.currentSessionID,
            tea: tea,
            startedAt: startedAt,
            elapsedSeconds: elapsedSeconds,
            infusionNumber: timerCoordinator.infusionNumber
        )
    }

    private func refreshNotificationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run {
            notificationsDenied = settings.authorizationStatus == .denied
        }
    }
}

private struct RecentBrewRow: View {
    let session: BrewSession
    let tea: Tea
    let onBrewAgain: () -> Void

    private var completedAt: Date {
        session.completedAt ?? session.startedAt
    }

    var body: some View {
        Button(action: onBrewAgain) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) {
                    TeaIconView(tea: tea, size: 44)

                    VStack(alignment: .leading, spacing: 5) {
                        Text(tea.name)
                            .font(.headline)
                            .foregroundStyle(SteeprPalette.ink)

                        HStack(spacing: 6) {
                            Text("Last brewed")
                            Text(completedAt, style: .relative)
                            Text("•")
                            Label(formatDuration(tea.effectiveSteepSeconds), systemImage: "clock")
                        }
                        .font(.footnote)
                        .foregroundStyle(SteeprPalette.inkSecondary)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "play.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(SteeprPalette.accentSolid))
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        TeaIconView(tea: tea, size: 40)
                        Text(tea.name)
                            .font(.headline)
                            .foregroundStyle(SteeprPalette.ink)
                        Spacer()
                        Image(systemName: "play.fill")
                            .foregroundStyle(SteeprPalette.accentSolid)
                    }

                    Text("Last brewed \(completedAt.formatted(.relative(presentation: .named))) · \(formatDuration(tea.effectiveSteepSeconds))")
                        .font(.footnote)
                        .foregroundStyle(SteeprPalette.inkSecondary)
                }
            }
        }
        .buttonStyle(.plain)
        .padding(14)
        .background(SteeprPalette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(SteeprPalette.controlStroke, lineWidth: 1)
        }
        .accessibilityLabel("Brew \(tea.name) again, \(formatDuration(tea.effectiveSteepSeconds))")
        .accessibilityHint("Starts a new timer using your current timing")
    }
}

private struct FavoriteTeaCard: View {
    let tea: Tea
    let useCelsius: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            TeaIconView(tea: tea, size: 52)

            VStack(alignment: .leading, spacing: 6) {
                Text(tea.name)
                    .font(.headline)
                    .foregroundStyle(SteeprPalette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                TeaMetaLine(tea: tea, useCelsius: useCelsius)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 134, alignment: .leading)
        .background(SteeprPalette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(SteeprPalette.controlStroke, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}
