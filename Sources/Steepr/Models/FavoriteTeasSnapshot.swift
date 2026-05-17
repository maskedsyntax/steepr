import Foundation

struct FavoriteTeasSnapshot: Codable, Equatable {
    static let storageKey = "steepr.favoriteTeas"

    var generatedAt: Date
    var teas: [Tea]
}
