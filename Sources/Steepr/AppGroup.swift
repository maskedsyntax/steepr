import Foundation

enum AppGroup {
    static let identifier = "group.com.maskedsyntax.Steepr"

    static var userDefaults: UserDefaults {
        UserDefaults(suiteName: identifier) ?? .standard
    }
}
