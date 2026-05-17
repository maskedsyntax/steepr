import SwiftUI
import UserNotifications

@main
struct SteeprWatchApp: App {
    @StateObject private var store = WatchDataStore()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                WatchRootView()
            }
            .environmentObject(store)
            .task {
                await requestNotificationAuthorizationIfNeeded()
            }
        }
    }

    private func requestNotificationAuthorizationIfNeeded() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
    }
}
