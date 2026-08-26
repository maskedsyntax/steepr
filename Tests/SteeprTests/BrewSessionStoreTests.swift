import XCTest
@testable import Steepr

final class BrewSessionStoreTests: XCTestCase {
    func testRecordCompletionKeepsSingleSessionPerID() {
        let store = BrewSessionStore(modelContainer: SteeprModelContainer.make(inMemory: true))
        let tea = testTea()
        let sessionID = UUID()

        store.recordCompletion(sessionID: sessionID, tea: tea, startedAt: Date(), durationSeconds: 150)
        store.recordCompletion(sessionID: sessionID, tea: tea, startedAt: Date(), durationSeconds: 150)

        let matchingSessions = store.sessions.filter { $0.id == sessionID }
        XCTAssertEqual(matchingSessions.count, 1)
        XCTAssertEqual(matchingSessions.first?.teaSnapshotName, "Test Tea")
        XCTAssertNotNil(matchingSessions.first?.completedAt)
    }

    func testPersistsSessionsInSwiftData() {
        let container = SteeprModelContainer.make(inMemory: true)
        let firstStore = BrewSessionStore(modelContainer: container)
        let tea = testTea()
        let sessionID = UUID()

        firstStore.recordCompletion(sessionID: sessionID, tea: tea, startedAt: Date(), durationSeconds: 150)

        let restoredStore = BrewSessionStore(modelContainer: container)
        XCTAssertEqual(restoredStore.sessions.filter { $0.id == sessionID }.count, 1)
    }

    func testRecordsInfusionNumber() {
        let store = BrewSessionStore(modelContainer: SteeprModelContainer.make(inMemory: true))
        let tea = testTea()
        let sessionID = UUID()

        store.recordCompletion(
            sessionID: sessionID,
            tea: tea,
            startedAt: Date(),
            durationSeconds: 150,
            infusionNumber: 2
        )

        XCTAssertEqual(store.sessions.first?.infusionNumber, 2)
    }

    func testUpdatesJournalEntry() {
        let store = BrewSessionStore(modelContainer: SteeprModelContainer.make(inMemory: true))
        let tea = testTea()
        let sessionID = UUID()

        store.recordCompletion(sessionID: sessionID, tea: tea, startedAt: Date(), durationSeconds: 150)
        store.updateJournal(sessionID: sessionID, rating: 4, note: "Balanced and sweet.")

        XCTAssertEqual(store.sessions.first?.rating, 4)
        XCTAssertEqual(store.sessions.first?.note, "Balanced and sweet.")
    }

    func testJournalEntryPersistsInSwiftData() {
        let container = SteeprModelContainer.make(inMemory: true)
        let firstStore = BrewSessionStore(modelContainer: container)
        let tea = testTea()
        let sessionID = UUID()

        firstStore.recordCompletion(sessionID: sessionID, tea: tea, startedAt: Date(), durationSeconds: 150)
        firstStore.updateJournal(sessionID: sessionID, rating: 5, note: "Clean finish.", outcome: .good)

        let restoredStore = BrewSessionStore(modelContainer: container)
        let restoredSession = restoredStore.sessions.first { $0.id == sessionID }
        XCTAssertEqual(restoredSession?.rating, 5)
        XCTAssertEqual(restoredSession?.note, "Clean finish.")
        XCTAssertEqual(restoredSession?.outcome, .good)
    }

    func testJournalRatingIsClamped() {
        let store = BrewSessionStore(modelContainer: SteeprModelContainer.make(inMemory: true))
        let tea = testTea()
        let sessionID = UUID()

        store.recordCompletion(sessionID: sessionID, tea: tea, startedAt: Date(), durationSeconds: 150)
        store.updateJournal(sessionID: sessionID, rating: 8, note: "Too much.")

        XCTAssertEqual(store.sessions.first?.rating, 5)
    }

    func testDeletesSessionsByID() {
        let store = BrewSessionStore(modelContainer: SteeprModelContainer.make(inMemory: true))
        let tea = testTea()
        let firstID = UUID()
        let secondID = UUID()

        store.recordCompletion(sessionID: firstID, tea: tea, startedAt: Date(), durationSeconds: 150)
        store.recordCompletion(sessionID: secondID, tea: tea, startedAt: Date(), durationSeconds: 150)
        store.deleteSessions(ids: [firstID])

        XCTAssertNil(store.session(with: firstID))
        XCTAssertNotNil(store.session(with: secondID))
    }

    func testCompletedCountIgnoresCancelledSessions() {
        let store = BrewSessionStore(modelContainer: SteeprModelContainer.make(inMemory: true))
        let tea = testTea()

        store.recordCompletion(sessionID: UUID(), tea: tea, startedAt: Date(), durationSeconds: 150)
        store.recordCompletion(sessionID: UUID(), tea: tea, startedAt: Date(), durationSeconds: 150)
        store.recordCancellation(sessionID: UUID(), tea: tea, startedAt: Date(), elapsedSeconds: 20)

        XCTAssertEqual(store.completedCount, 2)
    }

    func testReviewThresholdIsReachedOnThirdCompletedBrew() {
        let store = BrewSessionStore(modelContainer: SteeprModelContainer.make(inMemory: true))
        let tea = testTea()

        store.recordCompletion(sessionID: UUID(), tea: tea, startedAt: Date(), durationSeconds: 150)
        store.recordCancellation(sessionID: UUID(), tea: tea, startedAt: Date(), elapsedSeconds: 10)
        XCTAssertLessThan(store.completedCount, 3, "A cancelled brew must not count toward the prompt")

        store.recordCompletion(sessionID: UUID(), tea: tea, startedAt: Date(), durationSeconds: 150)
        XCTAssertLessThan(store.completedCount, 3)

        store.recordCompletion(sessionID: UUID(), tea: tea, startedAt: Date(), durationSeconds: 150)
        XCTAssertGreaterThanOrEqual(store.completedCount, 3)
    }

    func testCompletedSessionsOnDayExcludesOtherDaysAndCancellations() {
        let store = BrewSessionStore(modelContainer: SteeprModelContainer.make(inMemory: true))
        let tea = testTea()
        let yesterday = Date().addingTimeInterval(-60 * 60 * 24)

        store.recordCompletion(sessionID: UUID(), tea: tea, startedAt: Date(), durationSeconds: 150)
        store.recordCompletion(sessionID: UUID(), tea: tea, startedAt: yesterday, durationSeconds: 150)
        store.recordCancellation(sessionID: UUID(), tea: tea, startedAt: Date(), elapsedSeconds: 30)

        // `recordCompletion` stamps completedAt with "now", so both completions land on today.
        XCTAssertEqual(store.completedSessions(on: Date()).count, 2)
        XCTAssertEqual(store.completedSessions(on: yesterday).count, 0)
    }

    func testReviewRequestFlagDefaultsFalseAndPersists() {
        let container = SteeprModelContainer.make(inMemory: true)
        let store = TeaStore(modelContainer: container)
        XCTAssertFalse(store.preferences.hasRequestedReview)

        store.markReviewRequested()
        XCTAssertTrue(store.preferences.hasRequestedReview)

        let restored = TeaStore(modelContainer: container)
        XCTAssertTrue(restored.preferences.hasRequestedReview, "The prompt must never be shown twice")
    }

    private func testTea() -> Tea {
        Tea(
            name: "Test Tea",
            symbolName: "leaf.fill",
            colorSlot: .green,
            steepSeconds: 150,
            temperatureCelsius: 80
        )
    }
}
