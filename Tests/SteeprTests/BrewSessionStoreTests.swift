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
