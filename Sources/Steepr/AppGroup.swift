import Foundation

enum AppGroup {
    static let identifier = "group.com.maskedsyntax.steepr"

    static var userDefaults: UserDefaults {
        UserDefaults(suiteName: identifier) ?? .standard
    }
}
