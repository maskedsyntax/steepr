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
        _ = TeaStore()

        let data = try XCTUnwrap(AppGroup.userDefaults.data(forKey: FavoriteTeasSnapshot.storageKey))
        let snapshot = try JSONDecoder().decode(FavoriteTeasSnapshot.self, from: data)

        XCTAssertLessThanOrEqual(snapshot.teas.count, 6)
        XCTAssertTrue(snapshot.teas.allSatisfy(\.isFavorite))
    }

    func testPublishesPreferencesSnapshotOnInit() throws {
        let store = TeaStore()

        let data = try XCTUnwrap(AppGroup.userDefaults.data(forKey: UserPreferencesSnapshot.storageKey))
        let snapshot = try JSONDecoder().decode(UserPreferencesSnapshot.self, from: data)

        XCTAssertEqual(snapshot.preferences, store.preferences)
    }
}
