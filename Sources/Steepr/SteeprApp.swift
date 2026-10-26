import SwiftUI

#if os(macOS)
import AppKit
#endif

@main
struct SteeprApp: App {
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppNotificationDelegate.self) private var notificationDelegate
    #endif

    @StateObject private var teaStore: TeaStore
    @StateObject private var brewSessionStore: BrewSessionStore
    @StateObject private var purchaseCoordinator: PurchaseCoordinator
    #if DEBUG
    private let screenshotSessionID: UUID?
    #endif
    
    init() {
        let teaStore = TeaStore()
        let brewSessionStore = BrewSessionStore()
        _teaStore = StateObject(wrappedValue: teaStore)
        _brewSessionStore = StateObject(wrappedValue: brewSessionStore)
        _purchaseCoordinator = StateObject(wrappedValue: PurchaseCoordinator())

        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--screenshot-learned-brew"),
           let tea = teaStore.teas.first(where: { $0.name == "Green" }) {
            let sessionID = UUID()
            teaStore.setOnboardingComplete(true)
            brewSessionStore.recordCompletion(
                sessionID: sessionID,
                tea: tea,
                startedAt: Date().addingTimeInterval(-150),
                durationSeconds: 150
            )
            screenshotSessionID = sessionID
        } else {
            screenshotSessionID = nil
        }
        #endif

        WatchSyncService.configure()
        NotificationService.configure()
        #if os(macOS)
        setupActivationPolicy()
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            #if DEBUG
            if let screenshotSessionID {
                LearnedBrewScreenshotView(sessionID: screenshotSessionID)
                    .environmentObject(teaStore)
                    .environmentObject(brewSessionStore)
            } else {
                appContent
            }
            #else
            appContent
            #endif
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        #endif
        .commands {
            SidebarCommands()
        }
    }

    private var appContent: some View {
        ContentView()
            .environmentObject(teaStore)
            .environmentObject(brewSessionStore)
            .environmentObject(purchaseCoordinator)
            .task {
                purchaseCoordinator.startTransactionUpdatesListener(store: teaStore, brewSessionStore: brewSessionStore)
                await purchaseCoordinator.refreshEntitlements(store: teaStore, brewSessionStore: brewSessionStore)
                await purchaseCoordinator.loadProducts()
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

#if DEBUG
private struct LearnedBrewScreenshotView: View {
    @EnvironmentObject private var teaStore: TeaStore
    let sessionID: UUID

    private var tea: Tea? {
        teaStore.teas.first(where: { $0.name == "Green" })
    }

    var body: some View {
        ZStack {
            SteeprPalette.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    if let tea {
                        ZStack {
                            Circle()
                                .fill(tea.colorSlot.color.opacity(0.14))
                                .frame(width: 96, height: 96)
                            Image(systemName: "checkmark")
                                .font(.system(size: 36, weight: .semibold))
                                .foregroundStyle(tea.colorSlot.color)
                        }

                        VStack(spacing: 8) {
                            Text("How was your Green?")
                                .font(.largeTitle.bold())
                                .foregroundStyle(SteeprPalette.ink)
                                .multilineTextAlignment(.center)
                            Text("Help Steepr learn your perfect cup.")
                                .font(.title3)
                                .foregroundStyle(SteeprPalette.inkSecondary)
                                .multilineTextAlignment(.center)
                        }

                        BrewJournalPrompt(
                            sessionID: sessionID,
                            dismissAfterSave: false,
                            initialOutcome: .tooWeak,
                            context: .completion
                        )

                        Text("Your recipe stays unchanged until you save.")
                            .font(.footnote)
                            .foregroundStyle(SteeprPalette.inkSecondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 72)
            }
        }
    }
}
#endif
