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
            let size = finalIcon.size
            let inset = size.width * 0.1 // 10% padding to match native icons
            let contentSize = size.width - (inset * 2)
            let radius = contentSize * 0.225
            
            // Mask the icon with rounded corners at its content size
            let maskedIcon = finalIcon.withRoundedCorners(radius: radius, targetSize: NSSize(width: contentSize, height: contentSize))
            
            // Draw it onto a padded canvas
            let paddedIcon = NSImage(size: size)
            paddedIcon.lockFocus()
            maskedIcon.draw(in: NSRect(x: inset, y: inset, width: contentSize, height: contentSize))
            paddedIcon.unlockFocus()
            
            NSApplication.shared.applicationIconImage = paddedIcon
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
    func withRoundedCorners(radius: CGFloat, targetSize: NSSize? = nil) -> NSImage {
        let destSize = targetSize ?? size
        let newImage = NSImage(size: destSize)
        newImage.lockFocus()
        let rect = NSRect(origin: .zero, size: destSize)
        let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
        path.addClip()
        self.draw(in: rect, from: NSRect(origin: .zero, size: size), operation: .sourceOver, fraction: 1.0)
        newImage.unlockFocus()
        return newImage
    }
}
