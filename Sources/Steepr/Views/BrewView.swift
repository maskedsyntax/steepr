import SwiftUI

struct BrewView: View {
    @EnvironmentObject private var teaStore: TeaStore
    @ObservedObject var timerCoordinator: TimerCoordinator
    @Binding var selectedTab: Int

    private let gridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
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
        }
    }

    private var idleContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("What are you brewing?")
                .font(.largeTitle.bold())
                .fixedSize(horizontal: false, vertical: true)

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
                }
                .buttonStyle(.bordered)
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

                VStack(spacing: 8) {
                    Text(tea.name)
                        .font(.title.bold())
                    Text(formatTemperature(tea.temperatureCelsius, useCelsius: teaStore.preferences.useCelsius))
                        .font(.headline)
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
                    }
                    .buttonStyle(.borderedProminent)

                    Button(role: .destructive) {
                        timerCoordinator.cancel()
                    } label: {
                        Label("Cancel", systemImage: "xmark")
                    }
                    .buttonStyle(.bordered)
                }
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

                HStack(spacing: 12) {
                    Button("Brew again") {
                        timerCoordinator.brewAgain(preferences: teaStore.preferences)
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Done") {
                        timerCoordinator.done()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
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
    }
}
