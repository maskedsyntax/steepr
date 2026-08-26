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
    var hasSeenBrewMilestoneProPrompt: Bool
    var firstOpenedAt: Date
    var hasSeenSettingsProPrompt: Bool
    /// Set once the App Store review prompt has been requested, so it is never asked twice.
    var hasRequestedReview: Bool
    /// Local-only display name shown on the profile screen.
    var displayName: String
    /// Local-only contact email. Not used for accounts or sync.
    var email: String
    /// Preferred tea type color slots (e.g. green, black).
    var preferredTeaTypeRawValues: [String]
    /// Default steep duration used when creating a custom tea.
    var defaultSteepSeconds: Int

    init(
        useCelsius: Bool,
        preAlertSeconds: Int?,
        hapticStyle: HapticStyle,
        soundEnabled: Bool,
        soundName: String,
        autoStartSameTea: Bool,
        notificationsAuthorized: Bool,
        onboardingComplete: Bool,
        proPurchased: Bool,
        hasSeenBrewMilestoneProPrompt: Bool = false,
        firstOpenedAt: Date = Date(),
        hasSeenSettingsProPrompt: Bool = false,
        hasRequestedReview: Bool = false,
        displayName: String = "",
        email: String = "",
        preferredTeaTypeRawValues: [String] = ["green"],
        defaultSteepSeconds: Int = 180
    ) {
        self.useCelsius = useCelsius
        self.preAlertSeconds = preAlertSeconds
        self.hapticStyle = hapticStyle
        self.soundEnabled = soundEnabled
        self.soundName = soundName
        self.autoStartSameTea = autoStartSameTea
        self.notificationsAuthorized = notificationsAuthorized
        self.onboardingComplete = onboardingComplete
        self.proPurchased = proPurchased
        self.hasSeenBrewMilestoneProPrompt = hasSeenBrewMilestoneProPrompt
        self.firstOpenedAt = firstOpenedAt
        self.hasSeenSettingsProPrompt = hasSeenSettingsProPrompt
        self.hasRequestedReview = hasRequestedReview
        self.displayName = displayName
        self.email = email
        self.preferredTeaTypeRawValues = preferredTeaTypeRawValues
        self.defaultSteepSeconds = defaultSteepSeconds
    }

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

    var preferredTeaTypes: Set<TeaColorSlot> {
        get {
            Set(preferredTeaTypeRawValues.compactMap(TeaColorSlot.init(rawValue:)))
        }
        set {
            preferredTeaTypeRawValues = TeaColorSlot.allCases
                .filter { newValue.contains($0) }
                .map(\.rawValue)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case useCelsius
        case preAlertSeconds
        case hapticStyle
        case soundEnabled
        case soundName
        case autoStartSameTea
        case notificationsAuthorized
        case onboardingComplete
        case proPurchased
        case hasSeenBrewMilestoneProPrompt
        case firstOpenedAt
        case hasSeenSettingsProPrompt
        case hasRequestedReview
        case displayName
        case email
        case preferredTeaTypeRawValues
        case defaultSteepSeconds
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        useCelsius = try container.decode(Bool.self, forKey: .useCelsius)
        preAlertSeconds = try container.decodeIfPresent(Int.self, forKey: .preAlertSeconds)
        hapticStyle = try container.decode(HapticStyle.self, forKey: .hapticStyle)
        soundEnabled = try container.decode(Bool.self, forKey: .soundEnabled)
        soundName = try container.decode(String.self, forKey: .soundName)
        autoStartSameTea = try container.decode(Bool.self, forKey: .autoStartSameTea)
        notificationsAuthorized = try container.decode(Bool.self, forKey: .notificationsAuthorized)
        onboardingComplete = try container.decode(Bool.self, forKey: .onboardingComplete)
        proPurchased = try container.decode(Bool.self, forKey: .proPurchased)
        hasSeenBrewMilestoneProPrompt = try container.decodeIfPresent(Bool.self, forKey: .hasSeenBrewMilestoneProPrompt) ?? false
        firstOpenedAt = try container.decodeIfPresent(Date.self, forKey: .firstOpenedAt) ?? Date()
        hasSeenSettingsProPrompt = try container.decodeIfPresent(Bool.self, forKey: .hasSeenSettingsProPrompt) ?? false
        hasRequestedReview = try container.decodeIfPresent(Bool.self, forKey: .hasRequestedReview) ?? false
        displayName = try container.decodeIfPresent(String.self, forKey: .displayName) ?? ""
        email = try container.decodeIfPresent(String.self, forKey: .email) ?? ""
        preferredTeaTypeRawValues = try container.decodeIfPresent([String].self, forKey: .preferredTeaTypeRawValues) ?? ["green"]
        defaultSteepSeconds = try container.decodeIfPresent(Int.self, forKey: .defaultSteepSeconds) ?? 180
    }
}
