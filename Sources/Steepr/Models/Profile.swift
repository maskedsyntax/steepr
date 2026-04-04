import Foundation

struct Profile: Codable, Identifiable, Equatable, Hashable {
    var id = UUID()
    var name: String
    var steps: [Step]

    static func == (lhs: Profile, rhs: Profile) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    var totalDuration: TimeInterval {
        steps.reduce(0) { $0 + $1.duration }
    }
}
