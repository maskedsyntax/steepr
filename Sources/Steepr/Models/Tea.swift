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

    var name: String {
        switch self {
        case .green: return "Green"
        case .black: return "Black"
        case .oolong: return "Oolong"
        case .white: return "White"
        case .herbal: return "Herbal"
        case .chai: return "Chai"
        case .puerh: return "Pu-erh"
        case .matcha: return "Matcha"
        case .customA: return "Blue"
        case .customB: return "Rose"
        }
    }

    var lightHex: String {
        switch self {
        case .green: return "#4A7C4E"
        case .black: return "#3D2817"
        case .oolong: return "#B8732F"
        case .white: return "#D4C5A0"
        case .herbal: return "#A8456B"
        case .chai: return "#8B4513"
        case .puerh: return "#5C3A21"
        case .matcha: return "#7BA428"
        case .customA: return "#4A5FC1"
        case .customB: return "#C14A7C"
        }
    }

    var darkHex: String {
        switch self {
        case .green: return "#6FA873"
        case .black: return "#6B4A33"
        case .oolong: return "#D89554"
        case .white: return "#E8DBB8"
        case .herbal: return "#C46688"
        case .chai: return "#B8693A"
        case .puerh: return "#8B5E3C"
        case .matcha: return "#9DC04A"
        case .customA: return "#7388D4"
        case .customB: return "#D47394"
        }
    }

    var color: Color {
        Color(light: lightHex, dark: darkHex)
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

    init(
        id: UUID = UUID(),
        name: String,
        symbolName: String,
        colorSlot: TeaColorSlot,
        steepSeconds: Int,
        temperatureCelsius: Int,
        caffeineMilligrams: Int? = nil,
        notes: String = "",
        isBuiltIn: Bool = false,
        isFavorite: Bool = false,
        favoriteRank: Int? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.symbolName = symbolName
        self.colorSlot = colorSlot
        self.steepSeconds = steepSeconds
        self.temperatureCelsius = temperatureCelsius
        self.caffeineMilligrams = caffeineMilligrams
        self.notes = notes
        self.isBuiltIn = isBuiltIn
        self.isFavorite = isFavorite
        self.favoriteRank = favoriteRank
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

extension Tea {
    var guidedReSteepIncrementSeconds: Int {
        switch colorSlot {
        case .green, .white:
            return 15
        case .oolong, .puerh:
            return 30
        case .black, .chai:
            return 20
        case .herbal:
            return 45
        case .matcha, .customA, .customB:
            return 0
        }
    }

    var supportsGuidedReSteep: Bool {
        guidedReSteepIncrementSeconds > 0
    }

    func steepSeconds(forInfusion infusionNumber: Int, proPurchased: Bool) -> Int {
        let infusion = max(1, infusionNumber)
        guard proPurchased, infusion > 1, supportsGuidedReSteep else {
            return steepSeconds
        }

        let addedSeconds = guidedReSteepIncrementSeconds * (infusion - 1)
        return min(steepSeconds + addedSeconds, steepSeconds + 180)
    }

    static let builtIns: [Tea] = [
        Tea(name: "Green", symbolName: "leaf.fill", colorSlot: .green, steepSeconds: 150, temperatureCelsius: 80, notes: "Lower heat keeps green tea smooth.", isBuiltIn: true, isFavorite: true, favoriteRank: 0),
        Tea(name: "Black", symbolName: "cup.and.saucer.fill", colorSlot: .black, steepSeconds: 240, temperatureCelsius: 95, notes: "A full, strong steep works best near boiling.", isBuiltIn: true, isFavorite: true, favoriteRank: 1),
        Tea(name: "Oolong", symbolName: "flame.fill", colorSlot: .oolong, steepSeconds: 210, temperatureCelsius: 90, notes: "Balanced heat opens darker and lighter oolongs.", isBuiltIn: true, isFavorite: true, favoriteRank: 2),
        Tea(name: "White", symbolName: "cloud.fill", colorSlot: .white, steepSeconds: 180, temperatureCelsius: 75, notes: "Delicate leaves prefer a cooler cup.", isBuiltIn: true, isFavorite: false, favoriteRank: nil),
        Tea(name: "Herbal", symbolName: "camera.macro", colorSlot: .herbal, steepSeconds: 300, temperatureCelsius: 100, caffeineMilligrams: nil, notes: "Most herbal blends want a longer infusion.", isBuiltIn: true, isFavorite: true, favoriteRank: 3),
        Tea(name: "Chai", symbolName: "sparkles", colorSlot: .chai, steepSeconds: 300, temperatureCelsius: 100, notes: "Spices need time and heat to bloom.", isBuiltIn: true, isFavorite: true, favoriteRank: 4),
        Tea(name: "Pu-erh", symbolName: "mountain.2.fill", colorSlot: .puerh, steepSeconds: 180, temperatureCelsius: 95, notes: "Rinse first if you prefer a cleaner cup.", isBuiltIn: true, isFavorite: false, favoriteRank: nil),
        Tea(name: "Matcha", symbolName: "circle.hexagongrid.fill", colorSlot: .matcha, steepSeconds: 30, temperatureCelsius: 75, notes: "Whisk briskly after a short bloom.", isBuiltIn: true, isFavorite: true, favoriteRank: 5)
    ]
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

    init(light: String, dark: String) {
        #if os(iOS)
        self.init(UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(Color(hex: dark)) : UIColor(Color(hex: light))
        })
        #elseif os(macOS)
        self.init(NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return isDark ? NSColor(Color(hex: dark)) : NSColor(Color(hex: light))
        })
        #else
        self.init(hex: light)
        #endif
    }
}
