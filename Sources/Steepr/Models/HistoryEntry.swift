import Foundation

struct HistoryEntry: Codable, Identifiable, Equatable, Hashable {
    var id = UUID()
    var date: Date
    var profileName: String
    var rating: Int // 1-5 stars
    var notes: String?
    
    static func == (lhs: HistoryEntry, rhs: HistoryEntry) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
