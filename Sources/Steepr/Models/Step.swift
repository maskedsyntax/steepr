import Foundation

struct Step: Codable, Identifiable, Equatable, Hashable {
    var id = UUID()
    var name: String
    var duration: TimeInterval // in seconds
    var notes: String?

    static func == (lhs: Step, rhs: Step) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
