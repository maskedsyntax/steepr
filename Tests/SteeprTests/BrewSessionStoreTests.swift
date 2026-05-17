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
