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
    var infusionNumber: Int

    init(
        sessionID: UUID,
        tea: Tea,
        state: ActiveTimerState,
        startedAt: Date,
        hapticStyle: HapticStyle,
        soundEnabled: Bool,
        durationSeconds: Int,
        secondsRemaining: Int,
        endDate: Date?,
        pausedRemainingSeconds: Int,
        infusionNumber: Int = 1
    ) {
        self.sessionID = sessionID
        self.tea = tea
        self.state = state
        self.startedAt = startedAt
        self.hapticStyle = hapticStyle
        self.soundEnabled = soundEnabled
        self.durationSeconds = durationSeconds
        self.secondsRemaining = secondsRemaining
        self.endDate = endDate
        self.pausedRemainingSeconds = pausedRemainingSeconds
        self.infusionNumber = max(1, infusionNumber)
    }

    var currentSecondsRemaining: Int {
        guard state == .running, let endDate else {
            return max(0, secondsRemaining)
        }

        return max(0, Int(ceil(endDate.timeIntervalSinceNow)))
    }

    private enum CodingKeys: String, CodingKey {
        case sessionID
        case tea
        case state
        case startedAt
        case hapticStyle
        case soundEnabled
        case durationSeconds
        case secondsRemaining
        case endDate
        case pausedRemainingSeconds
        case infusionNumber
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sessionID = try container.decode(UUID.self, forKey: .sessionID)
        tea = try container.decode(Tea.self, forKey: .tea)
        state = try container.decode(ActiveTimerState.self, forKey: .state)
        startedAt = try container.decode(Date.self, forKey: .startedAt)
        hapticStyle = try container.decode(HapticStyle.self, forKey: .hapticStyle)
        soundEnabled = try container.decode(Bool.self, forKey: .soundEnabled)
        durationSeconds = try container.decode(Int.self, forKey: .durationSeconds)
        secondsRemaining = try container.decode(Int.self, forKey: .secondsRemaining)
        endDate = try container.decodeIfPresent(Date.self, forKey: .endDate)
        pausedRemainingSeconds = try container.decode(Int.self, forKey: .pausedRemainingSeconds)
        infusionNumber = max(1, try container.decodeIfPresent(Int.self, forKey: .infusionNumber) ?? 1)
    }
}
