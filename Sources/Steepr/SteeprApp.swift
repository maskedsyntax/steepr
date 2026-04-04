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
        .windowToolbarStyle(.unified(showsTitle: false))
        .commands {
            SidebarCommands()
        }
    }
    
    private func setupActivationPolicy() {
        // This ensures the app becomes a foreground app and appears in the Dock/Switcher
        // even when run as a raw binary via 'swift run'
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        // Load and set the application icon
        if let iconImage = NSImage(contentsOfFile: "steepr-logo.png") {
            // Apply standard macOS rounded corner radius (~22.5% of width)
            let radius = iconImage.size.width * 0.225
            let maskedIcon = iconImage.withRoundedCorners(radius: radius)
            NSApplication.shared.applicationIconImage = maskedIcon
        }
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

extension NSImage {
    func withRoundedCorners(radius: CGFloat) -> NSImage {
        let destSize = NSSize(width: size.width, height: size.height)
        let newImage = NSImage(size: destSize)
        newImage.lockFocus()
        let rect = NSRect(origin: .zero, size: destSize)
        let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
        path.addClip()
        self.draw(in: rect)
        newImage.unlockFocus()
        return newImage
    }
}
