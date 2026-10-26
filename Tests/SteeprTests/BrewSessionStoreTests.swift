import XCTest
import SwiftData
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

    func testRecentCompletedSessionsExcludeCancellationsAndUseCompletionOrder() throws {
        let container = SteeprModelContainer.make(inMemory: true)
        let context = ModelContext(container)
        let now = Date()
        let older = BrewSession(
            teaID: UUID(),
            teaSnapshotName: "Older",
            startedAt: now.addingTimeInterval(-300),
            completedAt: now.addingTimeInterval(-60),
            actualSteepSeconds: 240
        )
        let newer = BrewSession(
            teaID: UUID(),
            teaSnapshotName: "Newer",
            startedAt: now.addingTimeInterval(-600),
            completedAt: now.addingTimeInterval(-30),
            actualSteepSeconds: 150
        )
        let cancelled = BrewSession(
            teaID: UUID(),
            teaSnapshotName: "Cancelled",
            startedAt: now,
            completedAt: now.addingTimeInterval(10),
            cancelledAt: now,
            actualSteepSeconds: 10
        )

        context.insert(PersistentBrewSession(session: older))
        context.insert(PersistentBrewSession(session: newer))
        context.insert(PersistentBrewSession(session: cancelled))
        try context.save()

        let store = BrewSessionStore(modelContainer: container)
        XCTAssertEqual(store.recentCompletedSessions.map(\.id), [newer.id, older.id])
    }

    func testRecentDistinctCompletedSessionsDeduplicatesAndSkipsUnavailableTeas() throws {
        let container = SteeprModelContainer.make(inMemory: true)
        let context = ModelContext(container)
        let now = Date()
        let firstTeaID = UUID()
        let secondTeaID = UUID()
        let deletedTeaID = UUID()
        let sessions = [
            BrewSession(teaID: firstTeaID, teaSnapshotName: "First again", startedAt: now, completedAt: now, actualSteepSeconds: 165),
            BrewSession(teaID: deletedTeaID, teaSnapshotName: "Deleted", startedAt: now, completedAt: now.addingTimeInterval(-10), actualSteepSeconds: 120),
            BrewSession(teaID: firstTeaID, teaSnapshotName: "First", startedAt: now, completedAt: now.addingTimeInterval(-20), actualSteepSeconds: 150),
            BrewSession(teaID: secondTeaID, teaSnapshotName: "Second", startedAt: now, completedAt: now.addingTimeInterval(-30), actualSteepSeconds: 240),
            BrewSession(teaID: UUID(), teaSnapshotName: "Cancelled", startedAt: now, cancelledAt: now, actualSteepSeconds: 5)
        ]
        sessions.forEach { context.insert(PersistentBrewSession(session: $0)) }
        try context.save()

        let store = BrewSessionStore(modelContainer: container)
        let result = store.recentDistinctCompletedSessions(availableTeaIDs: Set([firstTeaID, secondTeaID]))

        XCTAssertEqual(result.map(\.teaID), [firstTeaID, secondTeaID])
        XCTAssertEqual(result.first?.actualSteepSeconds, 165)
    }

    func testTimingSuggestionsUseActualTimeAndClampToSupportedRange() {
        XCTAssertEqual(BrewOutcome.tooWeak.suggestedSteepSeconds(actualSteepSeconds: 120), 135)
        XCTAssertEqual(BrewOutcome.tooStrong.suggestedSteepSeconds(actualSteepSeconds: 120), 105)
        XCTAssertEqual(BrewOutcome.tooStrong.suggestedSteepSeconds(actualSteepSeconds: 5), 15)
        XCTAssertEqual(BrewOutcome.tooWeak.suggestedSteepSeconds(actualSteepSeconds: 900), 900)
        XCTAssertNil(BrewOutcome.good.suggestedSteepSeconds(actualSteepSeconds: 120))
    }

    func testCompletionJournalOffersTimingSuggestionForEligibleSession() {
        let teaID = UUID()
        let session = BrewSession(
            teaID: teaID,
            teaSnapshotName: "Green",
            startedAt: Date(),
            completedAt: Date(),
            actualSteepSeconds: 150
        )

        let suggestion = BrewJournalContext.completion.suggestedTiming(
            for: session,
            outcome: .tooWeak,
            teaExists: true
        )

        XCTAssertEqual(suggestion, 165)
    }

    func testHistoryJournalNeverOffersTimingSuggestion() {
        let session = BrewSession(
            teaID: UUID(),
            teaSnapshotName: "Green",
            startedAt: Date(),
            completedAt: Date(),
            actualSteepSeconds: 150,
            outcome: .tooWeak
        )

        let suggestion = BrewJournalContext.history.suggestedTiming(
            for: session,
            outcome: session.outcome,
            teaExists: true
        )

        XCTAssertNil(suggestion, "Editing an old journal must not overwrite a newer personal timing")
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
