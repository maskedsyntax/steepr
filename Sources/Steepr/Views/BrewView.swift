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

    /// The newest completed session whose tea still exists in the current library.
    /// If a custom tea was deleted, continue looking so the card always remains actionable.
    private var repeatableRecentBrew: (session: BrewSession, tea: Tea)? {
        for session in brewSessionStore.recentCompletedSessions {
            if let tea = teaStore.tea(with: session.teaID) {
                return (session, tea)
            }
        }
        return nil
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

    /// Caffeine and brew count for today, or `nil` when nothing has been brewed yet.
    /// Teas deleted since a session was logged still count as a brew but contribute no caffeine.
    private var todayCaffeineSummary: (milligrams: Int, brews: Int)? {
        let completed = brewSessionStore.completedSessions(on: Date())
        guard !completed.isEmpty else { return nil }

        let milligrams = completed.reduce(into: 0) { total, session in
            total += teaStore.tea(with: session.teaID)?.caffeineMilligrams ?? 0
        }
        return (milligrams, completed.count)
    }

    private func todaySummaryRow(_ summary: (milligrams: Int, brews: Int)) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "bolt.fill")
                .font(.footnote)
                .foregroundStyle(SteeprPalette.accentSolid)
            Text("Today: \(summary.milligrams) mg from \(summary.brews) \(summary.brews == 1 ? "brew" : "brews")")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(SteeprPalette.inkSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(SteeprPalette.accentSolid.opacity(0.10))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Today: \(summary.milligrams) milligrams of caffeine from \(summary.brews) \(summary.brews == 1 ? "brew" : "brews")")
    }

    private var idleContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("What are you brewing?")
                    .font(.largeTitle.bold())
                    .foregroundStyle(SteeprPalette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Start a favorite tea or browse the full library.")
                    .font(.subheadline)
                    .foregroundStyle(SteeprPalette.inkSecondary)
            }

            if let summary = todayCaffeineSummary {
                todaySummaryRow(summary)
            }

            if !brewSessionStore.sessions.isEmpty {
                recentBrewSection
            }

            if teaStore.favoriteTeas.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "star")
                        .font(.system(size: 42, weight: .medium))
                        .foregroundStyle(SteeprPalette.inkSecondary)
                    Text("Pick your favorites")
                        .font(.title3.bold())
                        .foregroundStyle(SteeprPalette.ink)
                    Text("Choose a few teas in Library for one-tap brewing.")
                        .foregroundStyle(SteeprPalette.inkSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)

                Button("Pick your favorites") {
                    selectedTab = 1
                }
                .buttonStyle(.borderedProminent)
                .tint(SteeprPalette.accentSolid)
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
                    Text("Recent Brew")
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
                    Text("Recent Brew")
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

            if let recentBrew = repeatableRecentBrew {
                RecentBrewCard(
                    session: recentBrew.session,
                    tea: recentBrew.tea
                ) {
                    timerCoordinator.start(recentBrew.tea, preferences: teaStore.preferences)
                }
            } else {
                Text("No completed brews yet.")
                    .font(.subheadline)
                    .foregroundStyle(SteeprPalette.inkSecondary)
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
                            subtitle: "Ideal temperature"
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
                        onNext: {
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
        VStack(spacing: 0) {
            Spacer(minLength: 24)

            if let tea = timerCoordinator.activeTea {
                VStack(spacing: 18) {
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
                }
                .padding(.horizontal, 28)

                Spacer(minLength: 24)

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
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
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

private struct RecentBrewCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let session: BrewSession
    let tea: Tea
    let onBrewAgain: () -> Void

    private var completedAt: Date {
        session.completedAt ?? session.startedAt
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        TeaIconView(tea: tea, size: 48)

                        Text(tea.name)
                            .font(.headline)
                            .foregroundStyle(SteeprPalette.ink)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Last brewed")
                        Text(completedAt, style: .relative)
                        Label(formatDuration(session.actualSteepSeconds), systemImage: "clock")
                    }
                    .font(.footnote)
                    .foregroundStyle(SteeprPalette.inkSecondary)
                }
            } else {
                HStack(spacing: 12) {
                    TeaIconView(tea: tea, size: 48)

                    VStack(alignment: .leading, spacing: 5) {
                        Text(tea.name)
                            .font(.headline)
                            .foregroundStyle(SteeprPalette.ink)

                        HStack(spacing: 6) {
                            Text("Last brewed")
                            Text(completedAt, style: .relative)
                            Text("•")
                            Label(formatDuration(session.actualSteepSeconds), systemImage: "clock")
                        }
                        .font(.footnote)
                        .foregroundStyle(SteeprPalette.inkSecondary)
                    }

                    Spacer(minLength: 0)
                }
            }

            Button(action: onBrewAgain) {
                Label("Brew Again", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(SteeprPalette.accentSolid)
            .controlSize(.large)
            .accessibilityLabel("Brew \(tea.name) again")
            .accessibilityHint("Starts a new timer using the current tea profile")
        }
        .padding(14)
        .background(SteeprPalette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(SteeprPalette.controlStroke, lineWidth: 1)
        }
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
