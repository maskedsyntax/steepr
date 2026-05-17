import Foundation

struct UserPreferencesSnapshot: Codable, Equatable {
    static let storageKey = "steepr.preferences"

    var generatedAt: Date
    var preferences: UserPreferences
}
