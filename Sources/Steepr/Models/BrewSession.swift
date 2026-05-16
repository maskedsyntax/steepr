import Foundation

struct BrewSession: Codable, Identifiable, Equatable, Hashable {
    var id: UUID
    var teaID: UUID
    var teaSnapshotName: String
    var startedAt: Date
    var completedAt: Date?
    var cancelledAt: Date?
    var actualSteepSeconds: Int
    var infusionNumber: Int

    init(
        id: UUID = UUID(),
        teaID: UUID,
        teaSnapshotName: String,
        startedAt: Date,
        completedAt: Date? = nil,
        cancelledAt: Date? = nil,
        actualSteepSeconds: Int,
        infusionNumber: Int = 1
    ) {
        self.id = id
        self.teaID = teaID
        self.teaSnapshotName = teaSnapshotName
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.cancelledAt = cancelledAt
        self.actualSteepSeconds = actualSteepSeconds
        self.infusionNumber = infusionNumber
    }
}
