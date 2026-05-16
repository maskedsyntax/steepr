import SwiftUI

#if os(macOS)
import AppKit
#endif

@main
struct SteeprApp: App {
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppNotificationDelegate.self) private var notificationDelegate
    #endif

    @StateObject private var teaStore = TeaStore()
    
    init() {
        NotificationService.configure()
        #if os(macOS)
        setupActivationPolicy()
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(teaStore)
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
}
