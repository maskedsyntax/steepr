import Foundation
import SwiftData

@Model
final class PersistentTea {
    var id: UUID = UUID()
    var name: String = ""
    var symbolName: String = "leaf.fill"
    var colorSlotRawValue: String = TeaColorSlot.green.rawValue
    var steepSeconds: Int = 0
    var temperatureCelsius: Int = 0
    var caffeineMilligrams: Int?
    var notes: String = ""
    var isBuiltIn: Bool = false
    var isFavorite: Bool = false
    var favoriteRank: Int?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    /// JSON-encoded `[BrewStep]`. Empty/nil means use default steps from steep/temp.
    var stepsJSON: Data?

    init(tea: Tea) {
        self.id = tea.id
        self.name = tea.name
        self.symbolName = tea.symbolName
        self.colorSlotRawValue = tea.colorSlot.rawValue
        self.steepSeconds = tea.steepSeconds
        self.temperatureCelsius = tea.temperatureCelsius
        self.caffeineMilligrams = tea.caffeineMilligrams
        self.notes = tea.notes
        self.isBuiltIn = tea.isBuiltIn
        self.isFavorite = tea.isFavorite
        self.favoriteRank = tea.favoriteRank
        self.createdAt = tea.createdAt
        self.updatedAt = tea.updatedAt
        self.stepsJSON = Self.encodeSteps(tea.steps)
    }

    func apply(_ tea: Tea) {
        id = tea.id
        name = tea.name
        symbolName = tea.symbolName
        colorSlotRawValue = tea.colorSlot.rawValue
        steepSeconds = tea.steepSeconds
        temperatureCelsius = tea.temperatureCelsius
        caffeineMilligrams = tea.caffeineMilligrams
        notes = tea.notes
        isBuiltIn = tea.isBuiltIn
        isFavorite = tea.isFavorite
        favoriteRank = tea.favoriteRank
        createdAt = tea.createdAt
        updatedAt = tea.updatedAt
        stepsJSON = Self.encodeSteps(tea.steps)
    }

    var tea: Tea {
        Tea(
            id: id,
            name: name,
            symbolName: symbolName,
            colorSlot: TeaColorSlot(rawValue: colorSlotRawValue) ?? .green,
            steepSeconds: steepSeconds,
            temperatureCelsius: temperatureCelsius,
            caffeineMilligrams: caffeineMilligrams,
            notes: notes,
            isBuiltIn: isBuiltIn,
            isFavorite: isFavorite,
            favoriteRank: favoriteRank,
            createdAt: createdAt,
            updatedAt: updatedAt,
            steps: Self.decodeSteps(stepsJSON)
        )
    }

    private static func encodeSteps(_ steps: [BrewStep]) -> Data? {
        guard !steps.isEmpty else { return nil }
        return try? JSONEncoder().encode(steps)
    }

    private static func decodeSteps(_ data: Data?) -> [BrewStep] {
        guard let data else { return [] }
        return (try? JSONDecoder().decode([BrewStep].self, from: data)) ?? []
    }
}

@Model
final class PersistentUserPreferences {
    var id: String = "default"
    var useCelsius: Bool = false
    var preAlertSeconds: Int?
    var hapticStyleRawValue: String = HapticStyle.standard.rawValue
    var soundEnabled: Bool = true
    var soundName: String = "Default"
    var autoStartSameTea: Bool = false
    var notificationsAuthorized: Bool = false
    var onboardingComplete: Bool = false
    var proPurchased: Bool = false
    var hasSeenBrewMilestoneProPrompt: Bool = false
    var firstOpenedAt: Date = Date()
    var hasSeenSettingsProPrompt: Bool = false
    var hasRequestedReview: Bool = false
    var displayName: String = ""
    var email: String = ""
    var preferredTeaTypeRawValues: [String] = ["green"]
    var defaultSteepSeconds: Int = 180

    init(preferences: UserPreferences, id: String = "default") {
        self.id = id
        self.useCelsius = preferences.useCelsius
        self.preAlertSeconds = preferences.preAlertSeconds
        self.hapticStyleRawValue = preferences.hapticStyle.rawValue
        self.soundEnabled = preferences.soundEnabled
        self.soundName = preferences.soundName
        self.autoStartSameTea = preferences.autoStartSameTea
        self.notificationsAuthorized = preferences.notificationsAuthorized
        self.onboardingComplete = preferences.onboardingComplete
        self.proPurchased = preferences.proPurchased
        self.hasSeenBrewMilestoneProPrompt = preferences.hasSeenBrewMilestoneProPrompt
        self.firstOpenedAt = preferences.firstOpenedAt
        self.hasSeenSettingsProPrompt = preferences.hasSeenSettingsProPrompt
        self.hasRequestedReview = preferences.hasRequestedReview
        self.displayName = preferences.displayName
        self.email = preferences.email
        self.preferredTeaTypeRawValues = preferences.preferredTeaTypeRawValues
        self.defaultSteepSeconds = preferences.defaultSteepSeconds
    }

    func apply(_ preferences: UserPreferences) {
        useCelsius = preferences.useCelsius
        preAlertSeconds = preferences.preAlertSeconds
        hapticStyleRawValue = preferences.hapticStyle.rawValue
        soundEnabled = preferences.soundEnabled
        soundName = preferences.soundName
        autoStartSameTea = preferences.autoStartSameTea
        notificationsAuthorized = preferences.notificationsAuthorized
        onboardingComplete = preferences.onboardingComplete
        proPurchased = preferences.proPurchased
        hasSeenBrewMilestoneProPrompt = preferences.hasSeenBrewMilestoneProPrompt
        firstOpenedAt = preferences.firstOpenedAt
        hasSeenSettingsProPrompt = preferences.hasSeenSettingsProPrompt
        hasRequestedReview = preferences.hasRequestedReview
        displayName = preferences.displayName
        email = preferences.email
        preferredTeaTypeRawValues = preferences.preferredTeaTypeRawValues
        defaultSteepSeconds = preferences.defaultSteepSeconds
    }

    var preferences: UserPreferences {
        UserPreferences(
            useCelsius: useCelsius,
            preAlertSeconds: preAlertSeconds,
            hapticStyle: HapticStyle(rawValue: hapticStyleRawValue) ?? .standard,
            soundEnabled: soundEnabled,
            soundName: soundName,
            autoStartSameTea: autoStartSameTea,
            notificationsAuthorized: notificationsAuthorized,
            onboardingComplete: onboardingComplete,
            proPurchased: proPurchased,
            hasSeenBrewMilestoneProPrompt: hasSeenBrewMilestoneProPrompt,
            firstOpenedAt: firstOpenedAt,
            hasSeenSettingsProPrompt: hasSeenSettingsProPrompt,
            hasRequestedReview: hasRequestedReview,
            displayName: displayName,
            email: email,
            preferredTeaTypeRawValues: preferredTeaTypeRawValues,
            defaultSteepSeconds: defaultSteepSeconds
        )
    }
}

@Model
final class PersistentBrewSession {
    var id: UUID = UUID()
    var teaID: UUID = UUID()
    var teaSnapshotName: String = ""
    var startedAt: Date = Date()
    var completedAt: Date?
    var cancelledAt: Date?
    var actualSteepSeconds: Int = 0
    var infusionNumber: Int = 1
    var rating: Int?
    var note: String = ""
    var outcomeRawValue: String?

    init(session: BrewSession) {
        self.id = session.id
        self.teaID = session.teaID
        self.teaSnapshotName = session.teaSnapshotName
        self.startedAt = session.startedAt
        self.completedAt = session.completedAt
        self.cancelledAt = session.cancelledAt
        self.actualSteepSeconds = session.actualSteepSeconds
        self.infusionNumber = session.infusionNumber
        self.rating = session.rating
        self.note = session.note
        self.outcomeRawValue = session.outcome?.rawValue
    }

    func apply(_ session: BrewSession) {
        id = session.id
        teaID = session.teaID
        teaSnapshotName = session.teaSnapshotName
        startedAt = session.startedAt
        completedAt = session.completedAt
        cancelledAt = session.cancelledAt
        actualSteepSeconds = session.actualSteepSeconds
        infusionNumber = session.infusionNumber
        rating = session.rating
        note = session.note
        outcomeRawValue = session.outcome?.rawValue
    }

    var session: BrewSession {
        BrewSession(
            id: id,
            teaID: teaID,
            teaSnapshotName: teaSnapshotName,
            startedAt: startedAt,
            completedAt: completedAt,
            cancelledAt: cancelledAt,
            actualSteepSeconds: actualSteepSeconds,
            infusionNumber: infusionNumber,
            rating: rating,
            note: note,
            outcome: outcomeRawValue.flatMap(BrewOutcome.init(rawValue:))
        )
    }
}

enum SteeprModelContainer {
    static let cloudKitContainerIdentifier = "iCloud.com.maskedsyntax.Steepr"
    static let shared = make()

    static func make(inMemory: Bool = false, cloudKitEnabled: Bool = false) -> ModelContainer {
        let schema = Schema([
            PersistentTea.self,
            PersistentUserPreferences.self,
            PersistentBrewSession.self
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: cloudKitEnabled ? .private(cloudKitContainerIdentifier) : .none
        )

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create Steepr SwiftData container: \(error)")
        }
    }
}
