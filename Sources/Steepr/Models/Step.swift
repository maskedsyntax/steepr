import Foundation

struct Step: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var duration: TimeInterval // in seconds
    var notes: String?

    static func == (lhs: Step, rhs: Step) -> Bool {
        lhs.id == rhs.id
    }
}
