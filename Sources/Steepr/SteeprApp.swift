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
        let iconName = "steepr-logo.png"
        var iconImage: NSImage?
        
        // Try to find it in the bundle first (if bundled)
        if let bundlePath = Bundle.main.path(forResource: "steepr-logo", ofType: "png") {
            iconImage = NSImage(contentsOfFile: bundlePath)
        } else if let fallbackImage = NSImage(contentsOfFile: iconName) {
            // Fallback to current directory (for swift run)
            iconImage = fallbackImage
        }

        if let finalIcon = iconImage {
            // Apply standard macOS rounded corner radius (~22.5% of width)
            let radius = finalIcon.size.width * 0.225
            let maskedIcon = finalIcon.withRoundedCorners(radius: radius)
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
