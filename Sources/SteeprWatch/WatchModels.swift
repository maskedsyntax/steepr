import Foundation
import SwiftUI

enum TeaColorSlot: String, Codable, CaseIterable, Identifiable {
    case green
    case black
    case oolong
    case white
    case herbal
    case chai
    case puerh
    case matcha
    case customA
    case customB

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .green: return Color(hex: "#6FA873")
        case .black: return Color(hex: "#6B4A33")
        case .oolong: return Color(hex: "#D89554")
        case .white: return Color(hex: "#E8DBB8")
        case .herbal: return Color(hex: "#C46688")
        case .chai: return Color(hex: "#B8693A")
        case .puerh: return Color(hex: "#8B5E3C")
        case .matcha: return Color(hex: "#9DC04A")
        case .customA: return Color(hex: "#7388D4")
        case .customB: return Color(hex: "#D47394")
        }
    }
}

struct Tea: Codable, Identifiable, Equatable, Hashable {
    var id: UUID
    var name: String
    var symbolName: String
    var colorSlot: TeaColorSlot
    var steepSeconds: Int
    var temperatureCelsius: Int
    var caffeineMilligrams: Int?
    var notes: String
    var isBuiltIn: Bool
    var isFavorite: Bool
    var favoriteRank: Int?
    var createdAt: Date
    var updatedAt: Date
}

extension Tea {
    static let builtIns: [Tea] = [
        Tea(id: UUID(), name: "Green", symbolName: "leaf.fill", colorSlot: .green, steepSeconds: 150, temperatureCelsius: 80, caffeineMilligrams: 30, notes: "", isBuiltIn: true, isFavorite: true, favoriteRank: 0, createdAt: Date(), updatedAt: Date()),
        Tea(id: UUID(), name: "Black", symbolName: "cup.and.saucer.fill", colorSlot: .black, steepSeconds: 240, temperatureCelsius: 95, caffeineMilligrams: 45, notes: "", isBuiltIn: true, isFavorite: true, favoriteRank: 1, createdAt: Date(), updatedAt: Date()),
        Tea(id: UUID(), name: "Oolong", symbolName: "flame.fill", colorSlot: .oolong, steepSeconds: 210, temperatureCelsius: 90, caffeineMilligrams: 35, notes: "", isBuiltIn: true, isFavorite: true, favoriteRank: 2, createdAt: Date(), updatedAt: Date()),
        Tea(id: UUID(), name: "Herbal", symbolName: "camera.macro", colorSlot: .herbal, steepSeconds: 300, temperatureCelsius: 100, caffeineMilligrams: nil, notes: "", isBuiltIn: true, isFavorite: true, favoriteRank: 3, createdAt: Date(), updatedAt: Date()),
        Tea(id: UUID(), name: "Chai", symbolName: "sparkles", colorSlot: .chai, steepSeconds: 300, temperatureCelsius: 100, caffeineMilligrams: 45, notes: "", isBuiltIn: true, isFavorite: true, favoriteRank: 4, createdAt: Date(), updatedAt: Date()),
        Tea(id: UUID(), name: "Matcha", symbolName: "circle.hexagongrid.fill", colorSlot: .matcha, steepSeconds: 30, temperatureCelsius: 75, caffeineMilligrams: 65, notes: "", isBuiltIn: true, isFavorite: true, favoriteRank: 5, createdAt: Date(), updatedAt: Date())
    ]
}

enum HapticStyle: String, Codable, CaseIterable, Identifiable {
    case standard
    case soft
    case strong

    var id: String { rawValue }
}

struct UserPreferences: Codable, Equatable {
    var useCelsius: Bool
    var preAlertSeconds: Int?
    var hapticStyle: HapticStyle
    var soundEnabled: Bool
    var soundName: String
    var autoStartSameTea: Bool
    var notificationsAuthorized: Bool
    var onboardingComplete: Bool
    var proPurchased: Bool

    static let defaults = UserPreferences(
        useCelsius: true,
        preAlertSeconds: nil,
        hapticStyle: .standard,
        soundEnabled: true,
        soundName: "Default",
        autoStartSameTea: false,
        notificationsAuthorized: false,
        onboardingComplete: true,
        proPurchased: false
    )
}

struct FavoriteTeasSnapshot: Codable, Equatable {
    static let storageKey = "steepr.favoriteTeas"

    var generatedAt: Date
    var teas: [Tea]
}

struct UserPreferencesSnapshot: Codable, Equatable {
    static let storageKey = "steepr.preferences"

    var generatedAt: Date
    var preferences: UserPreferences
}

extension Color {
    init(hex: String) {
        let value = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: value)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)

        let red = Double((rgb >> 16) & 0xff) / 255
        let green = Double((rgb >> 8) & 0xff) / 255
        let blue = Double(rgb & 0xff) / 255
        self.init(red: red, green: green, blue: blue)
    }
}
