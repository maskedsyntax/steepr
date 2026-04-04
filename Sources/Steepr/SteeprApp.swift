import SwiftUI
import UserNotifications
import AppKit

@main
struct SteeprApp: App {
    @StateObject private var profileStore = ProfileStore()
    
    init() {
        requestNotificationPermission()
        setupActivationPolicy()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(profileStore)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            SidebarCommands()
        }
    }
    
    private func setupActivationPolicy() {
        // This ensures the app becomes a foreground app and appears in the Dock/Switcher
        // even when run as a raw binary via 'swift run'
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    private func requestNotificationPermission() {
        // Guard against crashes when running without a proper app bundle (e.g. via swift run)
        guard Bundle.main.bundleIdentifier != nil else {
            print("Skipping notification permission: Not running in an app bundle.")
            return
        }
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
}
