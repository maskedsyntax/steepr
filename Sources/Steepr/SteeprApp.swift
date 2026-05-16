import SwiftUI
import UserNotifications

#if os(macOS)
import AppKit
#endif

@main
struct SteeprApp: App {
    @StateObject private var profileStore = ProfileStore()
    @StateObject private var historyStore = HistoryStore()
    
    init() {
        requestNotificationPermission()
        #if os(macOS)
        setupActivationPolicy()
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(profileStore)
                .environmentObject(historyStore)
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        #endif
        .commands {
            SidebarCommands()
        }
    }
    
    #if os(macOS)
    private func setupActivationPolicy() {
        // This ensures the app becomes a foreground app and appears in the Dock/Switcher
        // even when run as a raw binary via 'swift run'
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    #endif
    
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
