import SwiftUI
import UserNotifications

struct OnboardingView: View {
    @EnvironmentObject private var teaStore: TeaStore
    @Environment(\.dismiss) private var dismiss
    @State private var page = 0

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            TabView(selection: $page) {
                welcomePage.tag(0)
                favoritesPage.tag(1)
                notificationsPage.tag(2)
            }
            #if os(iOS)
            .tabViewStyle(.page(indexDisplayMode: .never))
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") { finish() }
                }
            }
        }
    }

    // MARK: - Pages

    private var welcomePage: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(TeaColorSlot.green.color.opacity(0.12))
                        .frame(width: 128, height: 128)
                    Image("SteeprLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 84, height: 84)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }

                VStack(spacing: 6) {
                    Text("Steepr")
                        .font(.largeTitle.bold())
                    Text("The perfect steep, every time.")
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)

            Spacer()

            VStack(alignment: .leading, spacing: 20) {
                OnboardingPoint(
                    symbol: "timer",
                    title: "Right time, right temperature",
                    detail: "Every tea type gets its own steep time and temperature."
                )
                OnboardingPoint(
                    symbol: "applewatch",
                    title: "Brews on your wrist",
                    detail: "Start and monitor timers directly from Apple Watch."
                )
                OnboardingPoint(
                    symbol: "arrow.clockwise",
                    title: "Guided re-steeps",
                    detail: "Timing adjusts automatically for each infusion."
                )
            }
            .padding(.horizontal)

            Spacer()

            Button("Get started") {
                page = 1
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(maxWidth: .infinity)
            .padding()
        }
    }

    private var favoritesPage: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Pick your teas.")
                            .font(.largeTitle.bold())
                        Text("Selected teas appear on your Brew screen and Apple Watch. You can change this any time in Library.")
                            .foregroundStyle(.secondary)
                    }

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(teaStore.builtInTeas) { tea in
                            Button {
                                teaStore.toggleFavorite(tea)
                            } label: {
                                HStack {
                                    TeaIconView(tea: tea, size: 40)
                                    Text(tea.name)
                                        .font(.headline)
                                    Spacer()
                                    Image(systemName: tea.isFavorite ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(tea.isFavorite ? TeaColorSlot.green.color : .secondary)
                                }
                                .padding(12)
                                .background(.background)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(.quaternary, lineWidth: 1)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
            }

            Button("Continue") {
                page = 2
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(teaStore.favoriteTeas.isEmpty)
            .frame(maxWidth: .infinity)
            .padding()
        }
    }

    private var notificationsPage: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 64, weight: .medium))
                        .foregroundStyle(TeaColorSlot.green.color)
                        .padding(.top, 24)
                        .frame(maxWidth: .infinity)

                    VStack(spacing: 8) {
                        Text("Know the moment it's ready.")
                            .font(.largeTitle.bold())
                            .multilineTextAlignment(.center)
                        Text("Steepr alerts you when your steep is done — even with your screen locked.")
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding()
            }

            VStack(spacing: 12) {
                Button("Allow notifications") {
                    requestNotifications()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)

                Button("Done") {
                    finish()
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
        }
    }

    // MARK: - Actions

    private func requestNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async {
                teaStore.preferences.notificationsAuthorized = granted
                finish()
            }
        }
    }

    private func finish() {
        teaStore.setOnboardingComplete(true)
        dismiss()
    }
}

private struct OnboardingPoint: View {
    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(TeaColorSlot.green.color)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
