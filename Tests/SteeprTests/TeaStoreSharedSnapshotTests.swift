import XCTest
import SwiftData
@testable import Steepr

final class TeaStoreSharedSnapshotTests: XCTestCase {
    override func setUp() {
        super.setUp()
        AppGroup.userDefaults.removeObject(forKey: FavoriteTeasSnapshot.storageKey)
        AppGroup.userDefaults.removeObject(forKey: UserPreferencesSnapshot.storageKey)
    }

    override func tearDown() {
        AppGroup.userDefaults.removeObject(forKey: FavoriteTeasSnapshot.storageKey)
        AppGroup.userDefaults.removeObject(forKey: UserPreferencesSnapshot.storageKey)
        super.tearDown()
    }

    func testFreshLibrarySeedsAllPresetsWithQuickPicksAndNoFavorites() {
        let store = TeaStore(modelContainer: SteeprModelContainer.make(inMemory: true))

        XCTAssertEqual(store.builtInTeas.count, 36)
        XCTAssertEqual(store.quickPickTeas.map(\.name), Tea.quickPickNames)
        XCTAssertTrue(store.favoriteTeas.isEmpty)
        XCTAssertEqual(Set(store.builtInTeas.map(\.id)).count, 36)
    }

    func testNewPresetsSeedOnceWithoutChangingSavedFavorites() throws {
        let container = SteeprModelContainer.make(inMemory: true)
        let context = ModelContext(container)
        for (index, preset) in Tea.builtIns.prefix(8).enumerated() {
            var tea = preset
            if index == 0 {
                tea.isFavorite = true
                tea.favoriteRank = 0
            }
            context.insert(PersistentTea(tea: tea))
        }
        try context.save()

        let upgradedStore = TeaStore(modelContainer: container)
        XCTAssertEqual(upgradedStore.builtInTeas.count, 36)
        XCTAssertEqual(upgradedStore.favoriteTeas.map(\.id), [Tea.builtIns[0].id])

        let reopenedStore = TeaStore(modelContainer: container)
        XCTAssertEqual(reopenedStore.builtInTeas.count, 36)
        XCTAssertEqual(reopenedStore.favoriteTeas.map(\.id), [Tea.builtIns[0].id])
    }

    func testPublishesFavoriteTeasSnapshotOnInit() throws {
        _ = TeaStore(modelContainer: SteeprModelContainer.make(inMemory: true))

        let data = try XCTUnwrap(AppGroup.userDefaults.data(forKey: FavoriteTeasSnapshot.storageKey))
        let snapshot = try JSONDecoder().decode(FavoriteTeasSnapshot.self, from: data)

        XCTAssertLessThanOrEqual(snapshot.teas.count, 6)
        XCTAssertTrue(snapshot.teas.allSatisfy(\.isFavorite))
    }

    func testPublishesPreferencesSnapshotOnInit() throws {
        let store = TeaStore(modelContainer: SteeprModelContainer.make(inMemory: true))

        let data = try XCTUnwrap(AppGroup.userDefaults.data(forKey: UserPreferencesSnapshot.storageKey))
        let snapshot = try JSONDecoder().decode(UserPreferencesSnapshot.self, from: data)

        XCTAssertEqual(snapshot.preferences, store.preferences)
    }

    func testPersistsSettingsProPromptState() {
        let container = SteeprModelContainer.make(inMemory: true)
        let firstStore = TeaStore(modelContainer: container)

        firstStore.markSettingsProPromptSeen()

        let restoredStore = TeaStore(modelContainer: container)
        XCTAssertTrue(restoredStore.preferences.hasSeenSettingsProPrompt)
    }

    func testPersistsCustomTeaInSwiftData() {
        let container = SteeprModelContainer.make(inMemory: true)
        let firstStore = TeaStore(modelContainer: container)
        let tea = Tea(
            name: "Test Oolong",
            symbolName: "leaf.fill",
            colorSlot: .oolong,
            steepSeconds: 210,
            temperatureCelsius: 90
        )

        firstStore.addCustomTea(tea)

        let restoredStore = TeaStore(modelContainer: container)
        XCTAssertNotNil(restoredStore.teas.first { $0.id == tea.id })
    }

    func testPersonalTimingPersistsAndPublishesToFavorites() throws {
        let container = SteeprModelContainer.make(inMemory: true)
        let firstStore = TeaStore(modelContainer: container)
        let tea = try XCTUnwrap(firstStore.quickPickTeas.first)
        firstStore.toggleFavorite(tea)

        firstStore.setPreferredSteepSeconds(tea.steepSeconds + 15, for: tea.id)

        let restoredStore = TeaStore(modelContainer: container)
        XCTAssertEqual(restoredStore.tea(with: tea.id)?.preferredSteepSeconds, tea.steepSeconds + 15)

        let data = try XCTUnwrap(AppGroup.userDefaults.data(forKey: FavoriteTeasSnapshot.storageKey))
        let snapshot = try JSONDecoder().decode(FavoriteTeasSnapshot.self, from: data)
        XCTAssertEqual(snapshot.teas.first { $0.id == tea.id }?.effectiveSteepSeconds, tea.steepSeconds + 15)
    }

    func testResetAndManualRecipeEditClearPersonalTiming() throws {
        let store = TeaStore(modelContainer: SteeprModelContainer.make(inMemory: true))
        let original = try XCTUnwrap(store.teas.first)

        store.setPreferredSteepSeconds(200, for: original.id)
        store.setPreferredSteepSeconds(nil, for: original.id)
        XCTAssertNil(store.tea(with: original.id)?.preferredSteepSeconds)

        store.setPreferredSteepSeconds(200, for: original.id)
        var edited = try XCTUnwrap(store.tea(with: original.id))
        edited.steepSeconds += 30
        store.updateTea(edited)
        XCTAssertNil(store.tea(with: original.id)?.preferredSteepSeconds)
    }

    func testLegacyTeaJSONDecodesWithoutPersonalTiming() throws {
        let tea = Tea(
            name: "Legacy Tea",
            symbolName: "leaf.fill",
            colorSlot: .green,
            steepSeconds: 120,
            temperatureCelsius: 80
        )
        let encoded = try JSONEncoder().encode(tea)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        object.removeValue(forKey: "preferredSteepSeconds")
        let legacyData = try JSONSerialization.data(withJSONObject: object)

        let decoded = try JSONDecoder().decode(Tea.self, from: legacyData)
        XCTAssertNil(decoded.preferredSteepSeconds)
        XCTAssertEqual(decoded.effectiveSteepSeconds, 120)
    }

    func testFavoriteReorderPersistsAndPublishesInSnapshotOrder() throws {
        let container = SteeprModelContainer.make(inMemory: true)
        let firstStore = TeaStore(modelContainer: container)
        for tea in firstStore.quickPickTeas.prefix(3) {
            firstStore.toggleFavorite(tea)
        }
        let original = firstStore.favoriteTeas
        XCTAssertGreaterThan(original.count, 1)

        firstStore.moveFavorite(from: IndexSet(integer: 0), to: original.count)
        let expectedIDs = Array(original.dropFirst().map(\.id)) + [original[0].id]
        XCTAssertEqual(firstStore.favoriteTeas.map(\.id), expectedIDs)

        let restoredStore = TeaStore(modelContainer: container)
        XCTAssertEqual(restoredStore.favoriteTeas.map(\.id), expectedIDs)

        let data = try XCTUnwrap(AppGroup.userDefaults.data(forKey: FavoriteTeasSnapshot.storageKey))
        let snapshot = try JSONDecoder().decode(FavoriteTeasSnapshot.self, from: data)
        XCTAssertEqual(snapshot.teas.map(\.id), expectedIDs)
    }

    func testMigratesLegacyJSONIntoSwiftData() throws {
        let directory = try makeTemporaryDirectory()
        let legacyTea = Tea(
            name: "Legacy Tea",
            symbolName: "leaf.fill",
            colorSlot: .green,
            steepSeconds: 120,
            temperatureCelsius: 80,
            isBuiltIn: false
        )
        let legacyPreferences = UserPreferences(
            useCelsius: true,
            preAlertSeconds: 30,
            hapticStyle: .strong,
            soundEnabled: true,
            soundName: "Default",
            autoStartSameTea: true,
            notificationsAuthorized: true,
            onboardingComplete: true,
            proPurchased: true
        )
        try JSONEncoder().encode([legacyTea]).write(to: directory.appendingPathComponent("teas.json"))
        try JSONEncoder().encode(legacyPreferences).write(to: directory.appendingPathComponent("preferences.json"))

        let store = TeaStore(
            modelContainer: SteeprModelContainer.make(inMemory: true),
            legacyDirectory: directory
        )

        XCTAssertNotNil(store.teas.first { $0.id == legacyTea.id })
        XCTAssertEqual(store.preferences, legacyPreferences)
    }

    private func makeTemporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("steepr-tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}
