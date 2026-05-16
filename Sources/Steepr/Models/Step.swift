import Foundation

enum TemperatureUnit: String, Codable, CaseIterable {
    case celsius = "°C"
    case fahrenheit = "°F"
}

struct Step: Codable, Identifiable, Equatable, Hashable {
    var id = UUID()
    var name: String
    var duration: TimeInterval // in seconds
    var temperature: Double?
    var temperatureUnit: TemperatureUnit = .celsius
    var notes: String?

    static func == (lhs: Step, rhs: Step) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    var formattedTemperature: String {
        guard let temp = temperature else { return "" }
        return "\(Int(temp))\(temperatureUnit.rawValue)"
    }
}
