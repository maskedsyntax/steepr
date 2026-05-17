import XCTest
@testable import Steepr

final class TimerCoordinatorTests: XCTestCase {
    override func setUp() {
        super.setUp()
        TimerCoordinator.notificationsEnabled = false
        AppGroup.userDefaults.removeObject(forKey: ActiveTimerSnapshot.storageKey)
        AppGroup.userDefaults.removeObject(forKey: FavoriteTeasSnapshot.storageKey)
        AppGroup.userDefaults.removeObject(forKey: UserPreferencesSnapshot.storageKey)
    }

    override func tearDown() {
        AppGroup.userDefaults.removeObject(forKey: ActiveTimerSnapshot.storageKey)
        AppGroup.userDefaults.removeObject(forKey: FavoriteTeasSnapshot.storageKey)
        AppGroup.userDefaults.removeObject(forKey: UserPreferencesSnapshot.storageKey)
        TimerCoordinator.notificationsEnabled = true
        super.tearDown()
    }

    func testStartConfiguresRunningTimer() {
        let tea = testTea(seconds: 90)
        let coordinator = TimerCoordinator()

        coordinator.start(tea, preferences: .defaults)

        XCTAssertEqual(coordinator.activeTea, tea)
        XCTAssertEqual(coordinator.state, .running)
        XCTAssertEqual(coordinator.durationSeconds, 90)
        XCTAssertGreaterThan(coordinator.secondsRemaining, 0)
        XCTAssertNotNil(coordinator.startedAt)
    }

    func testPauseAndResumeKeepsTimerState() {
        let tea = testTea(seconds: 90)
        let coordinator = TimerCoordinator()

        coordinator.start(tea, preferences: .defaults)
        coordinator.pause()

        XCTAssertEqual(coordinator.state, .paused)
        let pausedRemaining = coordinator.secondsRemaining

        coordinator.resume(preferences: .defaults)

        XCTAssertEqual(coordinator.state, .running)
        XCTAssertEqual(coordinator.secondsRemaining, pausedRemaining)
    }

    func testCancelClearsTimerState() {
        let coordinator = TimerCoordinator()

        coordinator.start(testTea(), preferences: .defaults)
        coordinator.cancel()

        XCTAssertNil(coordinator.activeTea)
        XCTAssertEqual(coordinator.state, .idle)
        XCTAssertEqual(coordinator.secondsRemaining, 0)
        XCTAssertEqual(coordinator.durationSeconds, 0)
    }

    func testRestoreRunningTimerFromPersistence() {
        let tea = testTea(seconds: 120)
        let preferences = UserPreferences.defaults
        let firstCoordinator = TimerCoordinator()
        firstCoordinator.start(tea, preferences: preferences)

        let restoredCoordinator = TimerCoordinator()
        restoredCoordinator.restoreIfNeeded(preferences: preferences)

        XCTAssertEqual(restoredCoordinator.activeTea, tea)
        XCTAssertEqual(restoredCoordinator.state, .running)
        XCTAssertEqual(restoredCoordinator.durationSeconds, 120)
        XCTAssertNotNil(restoredCoordinator.startedAt)
    }

    func testPersistsSharedActiveTimerSnapshot() throws {
        let tea = testTea(seconds: 75)
        let coordinator = TimerCoordinator()

        coordinator.start(tea, preferences: .defaults)

        let data = try XCTUnwrap(AppGroup.userDefaults.data(forKey: ActiveTimerSnapshot.storageKey))
        let snapshot = try JSONDecoder().decode(ActiveTimerSnapshot.self, from: data)

        XCTAssertEqual(snapshot.tea, tea)
        XCTAssertEqual(snapshot.state, .running)
        XCTAssertEqual(snapshot.durationSeconds, 75)
        XCTAssertGreaterThan(snapshot.currentSecondsRemaining, 0)
    }

    private func testTea(seconds: Int = 60) -> Tea {
        Tea(
            name: "Test Tea",
            symbolName: "leaf.fill",
            colorSlot: .green,
            steepSeconds: seconds,
            temperatureCelsius: 80
        )
    }
}
