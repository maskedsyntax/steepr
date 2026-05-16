import XCTest
@testable import Steepr

final class TimerCoordinatorTests: XCTestCase {
    override func setUp() {
        super.setUp()
        TimerCoordinator.notificationsEnabled = false
        UserDefaults.standard.removeObject(forKey: "steepr.activeTimer")
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "steepr.activeTimer")
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
