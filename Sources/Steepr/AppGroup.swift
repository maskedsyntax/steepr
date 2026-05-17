import Foundation

enum AppGroup {
    static let identifier = "group.com.steepr.app"

    static var userDefaults: UserDefaults {
        UserDefaults(suiteName: identifier) ?? .standard
    }
}
