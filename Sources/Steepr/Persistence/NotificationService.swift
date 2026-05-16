import Foundation
import UserNotifications

enum NotificationService {
    static let brewCompleteCategory = "BREW_COMPLETE"
    static let brewAgainAction = "BREW_AGAIN"
    static let dismissAction = "DISMISS"

    static func configure() {
        let brewAgain = UNNotificationAction(
            identifier: brewAgainAction,
            title: "Brew Again",
            options: [.foreground]
        )

        let dismiss = UNNotificationAction(
            identifier: dismissAction,
            title: "Dismiss",
            options: []
        )

        let category = UNNotificationCategory(
            identifier: brewCompleteCategory,
            actions: [brewAgain, dismiss],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
}

#if os(iOS)
import UIKit

final class AppNotificationDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        NotificationService.configure()
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        await MainActor.run {
            let store = TeaStore()
            let coordinator = TimerCoordinator()
            coordinator.restoreIfNeeded(preferences: store.preferences)

            switch response.actionIdentifier {
            case NotificationService.brewAgainAction:
                coordinator.brewAgain(preferences: store.preferences)
            case NotificationService.dismissAction, UNNotificationDismissActionIdentifier:
                coordinator.done()
            default:
                break
            }
        }
    }
}
#endif
