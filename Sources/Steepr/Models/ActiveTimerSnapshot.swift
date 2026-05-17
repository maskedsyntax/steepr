import Foundation

struct ActiveTimerSnapshot: Codable, Equatable {
    static let storageKey = "steepr.activeTimer"

    var sessionID: UUID
    var tea: Tea
    var state: ActiveTimerState
    var startedAt: Date
    var hapticStyle: HapticStyle
    var soundEnabled: Bool
    var durationSeconds: Int
    var secondsRemaining: Int
    var endDate: Date?
    var pausedRemainingSeconds: Int

    var currentSecondsRemaining: Int {
        guard state == .running, let endDate else {
            return max(0, secondsRemaining)
        }

        return max(0, Int(ceil(endDate.timeIntervalSinceNow)))
    }
}
