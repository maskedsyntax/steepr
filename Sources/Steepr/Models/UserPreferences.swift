import Foundation

enum HapticStyle: String, Codable, CaseIterable, Identifiable {
    case standard
    case soft
    case strong

    var id: String { rawValue }

    var label: String {
        switch self {
        case .standard: return "Standard"
        case .soft: return "Soft"
        case .strong: return "Strong"
        }
    }
}

struct UserPreferences: Codable, Equatable {
    var useCelsius: Bool
    var preAlertSeconds: Int?
    var hapticStyle: HapticStyle
    var soundEnabled: Bool
    var soundName: String
    var autoStartSameTea: Bool
    var notificationsAuthorized: Bool
    var onboardingComplete: Bool
    var proPurchased: Bool

    static let defaults = UserPreferences(
        useCelsius: Locale.current.measurementSystem != .us,
        preAlertSeconds: nil,
        hapticStyle: .standard,
        soundEnabled: true,
        soundName: "Default",
        autoStartSameTea: false,
        notificationsAuthorized: false,
        onboardingComplete: false,
        proPurchased: false
    )
}
