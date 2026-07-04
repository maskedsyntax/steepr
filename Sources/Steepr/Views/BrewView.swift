import SwiftUI
import UserNotifications

#if os(iOS)
import UIKit
#endif

struct BrewView: View {
    @EnvironmentObject private var teaStore: TeaStore
    @EnvironmentObject private var brewSessionStore: BrewSessionStore
    @Environment(\.openURL) private var openURL
    @ObservedObject var timerCoordinator: TimerCoordinator
    @Binding var selectedTab: Int
    @State private var notificationsDenied = false
    @State private var showingPaywall = false

    private let gridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if notificationsDenied {
                        notificationDeniedBanner
                    }

                    switch timerCoordinator.state {
                    case .idle:
                        idleContent
                    case .running, .paused:
                        activeTimerContent
                    case .completed:
                        completedContent
                    }
                }
                .padding()
                .frame(maxWidth: 640, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("Brew")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .task {
                await refreshNotificationStatus()
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView(trigger: "Guided infusions")
            }
        }
    }

    private var notificationDeniedBanner: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "bell.slash.fill")
                .foregroundStyle(.secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text("Notifications are off")
                    .font(.headline)
                Text("Enable notifications so Steepr can alert you when your tea is ready.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
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
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var idleContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("What are you brewing?")
                    .font(.largeTitle.bold())
                    .fixedSize(horizontal: false, vertical: true)
                Text("Start a favorite tea or browse the full library.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if teaStore.favoriteTeas.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "star")
                        .font(.system(size: 42, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text("Pick your favorites")
                        .font(.title3.bold())
                    Text("Choose a few teas in Library for one-tap brewing.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)

                Button("Pick your favorites") {
                    selectedTab = 1
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            } else {
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
                .controlSize(.large)
            }
        }
    }

    private var activeTimerContent: some View {
        VStack(spacing: 22) {
            if let tea = timerCoordinator.activeTea {
                TimerRingView(
                    progress: timerCoordinator.progress,
                    timeText: timerCoordinator.formattedTime(),
                    color: tea.colorSlot.color
                )
                .frame(maxWidth: 360)
                .accessibilityLabel("\(timerCoordinator.formattedTime()) remaining")
                .accessibilityAction(named: timerCoordinator.state == .running ? "Pause timer" : "Resume timer") {
                    if timerCoordinator.state == .running {
                        timerCoordinator.pause()
                    } else {
                        timerCoordinator.resume(preferences: teaStore.preferences)
                    }
                }

                VStack(spacing: 8) {
                    Text(tea.name)
                        .font(.title.bold())
                        .multilineTextAlignment(.center)
                    Text(formatTemperature(tea.temperatureCelsius, useCelsius: teaStore.preferences.useCelsius))
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("Infusion \(timerCoordinator.infusionNumber)")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 12) {
                    Button {
                        if timerCoordinator.state == .running {
                            timerCoordinator.pause()
                        } else {
                            timerCoordinator.resume(preferences: teaStore.preferences)
                        }
                    } label: {
                        Label(timerCoordinator.state == .running ? "Pause" : "Resume", systemImage: timerCoordinator.state == .running ? "pause.fill" : "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Button(role: .destructive) {
                        recordCancellationIfNeeded()
                        timerCoordinator.cancel()
                    } label: {
                        Label("Cancel", systemImage: "xmark")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: 420)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
    }

    private var completedContent: some View {
        VStack(spacing: 18) {
            if let tea = timerCoordinator.activeTea {
                TeaIconView(tea: tea, size: 88)

                Text("Done!")
                    .font(.largeTitle.bold())

                Text("Your \(tea.name) is ready.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Text("Infusion \(timerCoordinator.infusionNumber) complete")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)

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
                    .frame(maxWidth: 420)
                }

                HStack(spacing: 12) {
                    Button {
                        timerCoordinator.reSteep(preferences: teaStore.preferences)
                    } label: {
                        Label(nextInfusionTitle(for: tea), systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        timerCoordinator.done()
                    } label: {
                        Label("Done", systemImage: "checkmark")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: 420)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    @ViewBuilder
    private func reSteepSequenceHint(for tea: Tea) -> some View {
        if tea.supportsGuidedReSteep {
            if teaStore.preferences.proPurchased {
                Text("Next guided steep: \(formatDuration(nextInfusionSeconds(for: tea))).")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                Button {
                    showingPaywall = true
                } label: {
                    Label("Unlock guided infusion timing", systemImage: "sparkles")
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private func nextInfusionTitle(for tea: Tea) -> String {
        if teaStore.preferences.proPurchased, tea.supportsGuidedReSteep {
            return "Start infusion \(timerCoordinator.infusionNumber + 1)"
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

private struct FavoriteTeaCard: View {
    let tea: Tea
    let useCelsius: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            TeaIconView(tea: tea, size: 52)

            VStack(alignment: .leading, spacing: 6) {
                Text(tea.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                TeaMetaLine(tea: tea, useCelsius: useCelsius)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 134, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.quaternary, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}
