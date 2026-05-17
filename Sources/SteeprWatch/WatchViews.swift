import SwiftUI

struct WatchRootView: View {
    @EnvironmentObject private var store: WatchDataStore
    @StateObject private var timerCoordinator = WatchTimerCoordinator()

    var body: some View {
        Group {
            switch timerCoordinator.state {
            case .idle:
                teaList
            case .running, .paused:
                activeTimer
            case .completed:
                completedTimer
            }
        }
    }

    private var teaList: some View {
        List {
            ForEach(store.favoriteTeas) { tea in
                Button {
                    timerCoordinator.start(tea, preferences: store.preferences)
                } label: {
                    HStack(spacing: 10) {
                        TeaIcon(tea: tea, size: 34)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(tea.name)
                                .font(.headline)
                                .lineLimit(1)
                            Text(formatDuration(tea.steepSeconds))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .accessibilityLabel("Start \(tea.name) timer")
            }
        }
        .navigationTitle("Steepr")
    }

    private var activeTimer: some View {
        VStack(spacing: 8) {
            if let tea = timerCoordinator.activeTea {
                Text(tea.name)
                    .font(.headline)
                    .lineLimit(1)

                WatchTimerRing(
                    progress: timerCoordinator.progress,
                    timeText: timerCoordinator.formattedTime(),
                    color: tea.colorSlot.color
                )

                HStack(spacing: 8) {
                    Button {
                        if timerCoordinator.state == .running {
                            timerCoordinator.pause()
                        } else {
                            timerCoordinator.resume()
                        }
                    } label: {
                        Image(systemName: timerCoordinator.state == .running ? "pause.fill" : "play.fill")
                    }
                    .accessibilityLabel(timerCoordinator.state == .running ? "Pause timer" : "Resume timer")

                    Button(role: .destructive) {
                        timerCoordinator.cancel()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("Cancel timer")
                }
            }
        }
        .padding(.horizontal, 4)
    }

    private var completedTimer: some View {
        VStack(spacing: 10) {
            if let tea = timerCoordinator.activeTea {
                TeaIcon(tea: tea, size: 48)
                Text("Done")
                    .font(.title3.bold())
                Text(tea.name)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Button {
                        timerCoordinator.brewAgain()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .accessibilityLabel("Brew again")

                    Button {
                        timerCoordinator.done()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .accessibilityLabel("Done")
                }
            }
        }
    }
}

private struct TeaIcon: View {
    let tea: Tea
    var size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(tea.colorSlot.color.opacity(0.18))
            Image(systemName: tea.symbolName)
                .font(.system(size: size * 0.42, weight: .medium))
                .foregroundStyle(tea.colorSlot.color)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

private struct WatchTimerRing: View {
    let progress: Double
    let timeText: String
    let color: Color

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 9)
            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(style: StrokeStyle(lineWidth: 9, lineCap: .round))
                .foregroundStyle(color)
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : .linear(duration: 1), value: progress)
            Text(timeText)
                .font(.system(size: 34, weight: .bold, design: .rounded).monospacedDigit())
                .minimumScaleFactor(0.72)
        }
        .frame(width: 126, height: 126)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(timeText) remaining")
    }
}

func formatDuration(_ seconds: Int) -> String {
    let minutes = seconds / 60
    let remainingSeconds = seconds % 60
    if minutes == 0 {
        return "\(remainingSeconds)s"
    }
    if remainingSeconds == 0 {
        return "\(minutes)m"
    }
    return "\(minutes)m \(remainingSeconds)s"
}
