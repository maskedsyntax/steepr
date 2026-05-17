import Foundation

enum L10n {
    static func teaReady(_ teaName: String) -> String {
        String(format: localized("Your %@ is ready"), teaName)
    }

    static func steepedForTapToBrewAgain(_ duration: String) -> String {
        String(format: localized("Steeped for %@. Tap to brew again."), duration)
    }

    static func secondsLeft(_ seconds: Int) -> String {
        String(format: localized("%d seconds left"), seconds)
    }

    static func secondsLeftOnTea(_ seconds: Int, teaName: String) -> String {
        String(format: localized("%d seconds left on your %@."), seconds, teaName)
    }

    static func teaIsSteeping(_ teaName: String, duration: String) -> String {
        String(format: localized("%@ is steeping for %@."), teaName, duration)
    }

    static func pausedTea(_ teaName: String) -> String {
        String(format: localized("Paused %@."), teaName)
    }

    static func stoppedTea(_ teaName: String) -> String {
        String(format: localized("Stopped %@."), teaName)
    }

    static var teaNotFound: String {
        localized("I couldn't find that tea.")
    }

    static var noRunningTimer: String {
        localized("No tea timer is running.")
    }

    static var noActiveTimer: String {
        localized("No tea timer is active.")
    }

    private static func localized(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }
}
