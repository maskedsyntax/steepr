import Foundation

struct Profile: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var steps: [Step]

    static func == (lhs: Profile, rhs: Profile) -> Bool {
        lhs.id == rhs.id
    }
    
    var totalDuration: TimeInterval {
        steps.reduce(0) { $0 + $1.duration }
    }
}
