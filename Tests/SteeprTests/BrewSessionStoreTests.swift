import XCTest
@testable import Steepr

final class BrewSessionStoreTests: XCTestCase {
    func testRecordCompletionKeepsSingleSessionPerID() {
        let store = BrewSessionStore(fileName: "brew-sessions-test-\(UUID().uuidString).json")
        let tea = testTea()
        let sessionID = UUID()

        store.recordCompletion(sessionID: sessionID, tea: tea, startedAt: Date(), durationSeconds: 150)
        store.recordCompletion(sessionID: sessionID, tea: tea, startedAt: Date(), durationSeconds: 150)

        let matchingSessions = store.sessions.filter { $0.id == sessionID }
        XCTAssertEqual(matchingSessions.count, 1)
        XCTAssertEqual(matchingSessions.first?.teaSnapshotName, "Test Tea")
        XCTAssertNotNil(matchingSessions.first?.completedAt)
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
