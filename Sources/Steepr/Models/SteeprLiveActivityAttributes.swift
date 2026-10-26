import Foundation

#if canImport(ActivityKit) && os(iOS)
import ActivityKit

nonisolated struct SteeprLiveActivityAttributes: ActivityAttributes {
    nonisolated struct ContentState: Codable, Hashable {
        var state: String
        var endDate: Date?
        var secondsRemaining: Int
        var progress: Double
    }

    var sessionID: UUID
    var teaName: String
    var symbolName: String
    var durationSeconds: Int
}
#endif
