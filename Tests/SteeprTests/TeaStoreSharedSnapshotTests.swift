import XCTest
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

    func testFavoriteReorderPersistsAndPublishesInSnapshotOrder() throws {
        let container = SteeprModelContainer.make(inMemory: true)
        let firstStore = TeaStore(modelContainer: container)
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
