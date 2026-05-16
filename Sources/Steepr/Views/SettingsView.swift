import SwiftUI
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject private var teaStore: TeaStore
    @State private var showingPaywall = false
    @State private var notificationStatus = "Not requested"

    var body: some View {
        NavigationStack {
            Form {
                if !teaStore.preferences.proPurchased {
                    Section("Steep Pro") {
                        Button {
                            showingPaywall = true
                        } label: {
                            Label("Unlock Pro", systemImage: "sparkles")
                        }
                    }
                }

                Section("Brewing") {
                    Picker("Temperature", selection: $teaStore.preferences.useCelsius) {
                        Text("°F").tag(false)
                        Text("°C").tag(true)
                    }
                    .pickerStyle(.segmented)

                    LabeledContent("Time format", value: "M:SS")

                    Toggle("Pre-completion alert", isOn: Binding(
                        get: { teaStore.preferences.preAlertSeconds != nil },
                        set: { teaStore.preferences.preAlertSeconds = $0 ? 30 : nil }
                    ))

                    if teaStore.preferences.preAlertSeconds != nil {
                        Picker("Alert before", selection: Binding(
                            get: { teaStore.preferences.preAlertSeconds ?? 30 },
                            set: { teaStore.preferences.preAlertSeconds = $0 }
                        )) {
                            Text("10s").tag(10)
                            Text("30s").tag(30)
                            Text("1 min").tag(60)
                        }
                    }
                }

                Section("Notifications & Haptics") {
                    Button {
                        requestNotifications()
                    } label: {
                        LabeledContent("Notification permission", value: notificationStatus)
                    }

                    Picker("Completion haptic", selection: $teaStore.preferences.hapticStyle) {
                        ForEach(HapticStyle.allCases) { style in
                            HStack {
                                Text(style.label)
                                if style == .strong && !teaStore.preferences.proPurchased {
                                    Text("Pro")
                                }
                            }
                            .tag(style)
                        }
                    }
                    .onChange(of: teaStore.preferences.hapticStyle) { _, value in
                        if value == .strong && !teaStore.preferences.proPurchased {
                            teaStore.preferences.hapticStyle = .standard
                            showingPaywall = true
                        }
                    }

                    Toggle("Sound on completion", isOn: $teaStore.preferences.soundEnabled)
                    Picker("Sound", selection: $teaStore.preferences.soundName) {
                        Text("Default").tag("Default")
                        Text("Chime").tag("Chime")
                        Text("Soft Bell").tag("Soft Bell")
                    }
                    .disabled(!teaStore.preferences.soundEnabled)
                }

                Section("Watch") {
                    NavigationLink("Manage Watch favorites") {
                        ManageWatchFavoritesView()
                    }
                    Toggle("Auto-start same tea on complication tap", isOn: $teaStore.preferences.autoStartSameTea)
                }

                Section("Pro") {
                    Button("Restore purchases") {
                        teaStore.preferences.proPurchased = true
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0")
                    Link("Privacy policy", destination: URL(string: "https://steepr.maskedsyntax.com/privacy")!)
                    Link("Contact support", destination: URL(string: "mailto:support@maskedsyntax.com")!)
                    Text("Made by Aftaab Siddiqui")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .sheet(isPresented: $showingPaywall) {
                PaywallView(trigger: "Settings")
            }
            .task {
                await refreshNotificationStatus()
            }
        }
    }

    private func requestNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async {
                teaStore.preferences.notificationsAuthorized = granted
                notificationStatus = granted ? "Allowed" : "Denied"
            }
        }
    }

    private func refreshNotificationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run {
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                notificationStatus = "Allowed"
                teaStore.preferences.notificationsAuthorized = true
            case .denied:
                notificationStatus = "Denied"
                teaStore.preferences.notificationsAuthorized = false
            case .notDetermined:
                notificationStatus = "Not requested"
                teaStore.preferences.notificationsAuthorized = false
            @unknown default:
                notificationStatus = "Unknown"
            }
        }
    }
}

private struct ManageWatchFavoritesView: View {
    @EnvironmentObject private var teaStore: TeaStore

    var body: some View {
        List {
            Section("Favorites") {
                ForEach(teaStore.favoriteTeas) { tea in
                    HStack {
                        TeaIconView(tea: tea, size: 36)
                        Text(tea.name)
                    }
                }
                .onMove(perform: teaStore.moveFavorite)
            }

            Section {
                Text("The first six favorites appear on Apple Watch.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Watch Favorites")
        #if os(iOS)
        .toolbar {
            EditButton()
        }
        #endif
    }
}
