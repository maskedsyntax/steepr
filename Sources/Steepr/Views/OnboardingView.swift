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
            .tabViewStyle(.page)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") { finish() }
                }
            }
        }
    }

    private var welcomePage: some View {
        VStack(spacing: 22) {
            Image("SteeprLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 112, height: 112)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

            VStack(spacing: 8) {
                Text("Steepr")
                    .font(.largeTitle.bold())
                Text("The perfect cup, every time.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            Button("Get started") {
                page = 1
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }

    private var favoritesPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Pick 3 teas to start.")
                        .font(.largeTitle.bold())
                    Text("Choose up to six favorites for quick brewing and Apple Watch.")
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

                Button("Continue") {
                    page = 2
                }
                .buttonStyle(.borderedProminent)
                .disabled(teaStore.favoriteTeas.isEmpty)
            }
            .padding()
        }
    }

    private var notificationsPage: some View {
        VStack(spacing: 18) {
            Image(systemName: "applewatch.radiowaves.left.and.right")
                .font(.system(size: 64, weight: .medium))
                .foregroundStyle(TeaColorSlot.green.color)

            VStack(spacing: 8) {
                Text("Notifications & Watch")
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                Text("Steepr alerts you when tea is ready, even if your screen is locked.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button("Allow notifications") {
                requestNotifications()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Link("Set up on Watch", destination: URL(string: "https://steepr.maskedsyntax.com/support")!)
                .buttonStyle(.bordered)

            Button("Done") {
                finish()
            }
            .padding(.top, 8)
        }
        .padding()
    }

    private func requestNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async {
                teaStore.preferences.notificationsAuthorized = granted
            }
        }
    }

    private func finish() {
        teaStore.setOnboardingComplete(true)
        dismiss()
    }
}
