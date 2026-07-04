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
    var rating: Int?
    var note: String
    var outcome: BrewOutcome?

    init(
        id: UUID = UUID(),
        teaID: UUID,
        teaSnapshotName: String,
        startedAt: Date,
        completedAt: Date? = nil,
        cancelledAt: Date? = nil,
        actualSteepSeconds: Int,
        infusionNumber: Int = 1,
        rating: Int? = nil,
        note: String = "",
        outcome: BrewOutcome? = nil
    ) {
        self.id = id
        self.teaID = teaID
        self.teaSnapshotName = teaSnapshotName
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.cancelledAt = cancelledAt
        self.actualSteepSeconds = actualSteepSeconds
        self.infusionNumber = infusionNumber
        self.rating = rating
        self.note = note
        self.outcome = outcome
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case teaID
        case teaSnapshotName
        case startedAt
        case completedAt
        case cancelledAt
        case actualSteepSeconds
        case infusionNumber
        case rating
        case note
        case outcome
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        teaID = try container.decode(UUID.self, forKey: .teaID)
        teaSnapshotName = try container.decode(String.self, forKey: .teaSnapshotName)
        startedAt = try container.decode(Date.self, forKey: .startedAt)
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
        cancelledAt = try container.decodeIfPresent(Date.self, forKey: .cancelledAt)
        actualSteepSeconds = try container.decode(Int.self, forKey: .actualSteepSeconds)
        infusionNumber = max(1, try container.decodeIfPresent(Int.self, forKey: .infusionNumber) ?? 1)
        rating = try container.decodeIfPresent(Int.self, forKey: .rating)
        note = try container.decodeIfPresent(String.self, forKey: .note) ?? ""
        outcome = try container.decodeIfPresent(BrewOutcome.self, forKey: .outcome)
    }
}

enum BrewOutcome: String, Codable, CaseIterable, Identifiable, Hashable {
    case tooWeak
    case good
    case tooStrong

    var id: String { rawValue }

    var label: String {
        switch self {
        case .tooWeak: return "Too weak"
        case .good: return "Good"
        case .tooStrong: return "Too strong"
        }
    }

    var suggestion: String? {
        switch self {
        case .tooWeak: return "Try 15 seconds longer next time."
        case .good: return nil
        case .tooStrong: return "Try 15 seconds shorter next time."
        }
    }
}
