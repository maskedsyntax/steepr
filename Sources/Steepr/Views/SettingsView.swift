import SwiftUI
import UserNotifications

#if os(iOS)
import UIKit
#endif

struct SettingsView: View {
    @EnvironmentObject private var teaStore: TeaStore
    @EnvironmentObject private var brewSessionStore: BrewSessionStore
    @EnvironmentObject private var purchaseCoordinator: PurchaseCoordinator
    @Environment(\.openURL) private var openURL
    @State private var showingPaywall = false
    @State private var notificationStatus: NotificationPermissionStatus = .notRequested

    var body: some View {
        NavigationStack {
            Form {
                Section("Steepr Pro") {
                    if teaStore.preferences.proPurchased {
                        LabeledContent {
                            Text("Active")
                                .foregroundStyle(TeaColorSlot.green.color)
                        } label: {
                            Label("Steepr Pro", systemImage: "checkmark.seal.fill")
                        }
                    } else {
                        Button {
                            showingPaywall = true
                        } label: {
                            Label("Unlock Steepr Pro", systemImage: "sparkles")
                        }
                    }
                }

                Section("Brewing") {
                    Picker("Temperature", selection: $teaStore.preferences.useCelsius) {
                        Text("°F").tag(false)
                        Text("°C").tag(true)
                    }
                    .pickerStyle(.segmented)

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
                        handleNotificationPermissionTap()
                    } label: {
                        LabeledContent("Notification permission", value: notificationStatus.label)
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
                }

                Section("Purchases") {
                    Button("Restore purchases") {
                        Task {
                            await purchaseCoordinator.restorePurchases(store: teaStore, brewSessionStore: brewSessionStore)
                        }
                    }
                    Text(teaStore.preferences.proPurchased ? "Use restore if Pro ever stops showing as active on this device." : "Use restore if you already bought Pro on this Apple ID.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("About") {
                    LabeledContent("Version", value: appVersion)
                    if shouldShowSettingsProPrompt {
                        Button {
                            teaStore.markSettingsProPromptSeen()
                            showingPaywall = true
                        } label: {
                            Label("Keep your full tea journal", systemImage: "sparkles")
                        }
                    }
                    Link("Privacy policy", destination: URL(string: "https://steepr.maskedsyntax.com/privacy")!)
                    Link("Support", destination: URL(string: "https://steepr.maskedsyntax.com/support")!)
                    Link("Contact support", destination: URL(string: "mailto:support@maskedsyntax.com")!)
                }

                #if DEBUG
                Section("Debug") {
                    Button {
                        teaStore.setOnboardingComplete(false)
                    } label: {
                        Label("Replay onboarding", systemImage: "arrow.counterclockwise")
                    }
                }
                #endif
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

    private var shouldShowSettingsProPrompt: Bool {
        guard
            !teaStore.preferences.proPurchased,
            !teaStore.preferences.hasSeenSettingsProPrompt
        else {
            return false
        }

        return Date().timeIntervalSince(teaStore.preferences.firstOpenedAt) >= 14 * 24 * 60 * 60
    }

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String

        switch (version, build) {
        case let (version?, build?) where !build.isEmpty:
            return "\(version) (\(build))"
        case let (version?, _):
            return version
        case let (_, build?) where !build.isEmpty:
            return build
        default:
            return "Unknown"
        }
    }

    private func handleNotificationPermissionTap() {
        switch notificationStatus {
        case .notRequested:
            requestNotifications()
        case .denied:
            openSystemSettings()
        case .allowed, .unknown:
            Task {
                await refreshNotificationStatus()
            }
        }
    }

    private func requestNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async {
                teaStore.preferences.notificationsAuthorized = granted
                notificationStatus = granted ? .allowed : .denied
            }
        }
    }

    private func openSystemSettings() {
        #if os(iOS)
        if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
        }
        #endif
    }

    private func refreshNotificationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run {
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                notificationStatus = .allowed
                teaStore.preferences.notificationsAuthorized = true
            case .denied:
                notificationStatus = .denied
                teaStore.preferences.notificationsAuthorized = false
            case .notDetermined:
                notificationStatus = .notRequested
                teaStore.preferences.notificationsAuthorized = false
            @unknown default:
                notificationStatus = .unknown
            }
        }
    }
}

private enum NotificationPermissionStatus {
    case notRequested
    case allowed
    case denied
    case unknown

    var label: String {
        switch self {
        case .notRequested: return "Not requested"
        case .allowed: return "Allowed"
        case .denied: return "Denied"
        case .unknown: return "Unknown"
        }
    }
}
