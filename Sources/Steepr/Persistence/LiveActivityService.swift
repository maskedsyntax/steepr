import Foundation

#if canImport(ActivityKit) && os(iOS)
import ActivityKit

enum LiveActivityService {
    static func start(snapshot: ActiveTimerSnapshot) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        Task {
            await endAll(except: snapshot.sessionID)

            let attributes = SteeprLiveActivityAttributes(
                sessionID: snapshot.sessionID,
                teaName: snapshot.tea.name,
                symbolName: snapshot.tea.symbolName,
                durationSeconds: snapshot.durationSeconds
            )
            let content = ActivityContent(
                state: contentState(from: snapshot),
                staleDate: snapshot.endDate
            )

            _ = try? Activity.request(attributes: attributes, content: content)
        }
    }

    static func update(snapshot: ActiveTimerSnapshot) {
        Task {
            for activity in Activity<SteeprLiveActivityAttributes>.activities
                where activity.attributes.sessionID == snapshot.sessionID
            {
                let content = ActivityContent(
                    state: contentState(from: snapshot),
                    staleDate: snapshot.endDate
                )
                await activity.update(content)
            }
        }
    }

    static func end(sessionID: UUID? = nil) {
        Task {
            for activity in Activity<SteeprLiveActivityAttributes>.activities
                where sessionID == nil || activity.attributes.sessionID == sessionID
            {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }

    private static func endAll(except sessionID: UUID) async {
        for activity in Activity<SteeprLiveActivityAttributes>.activities
            where activity.attributes.sessionID != sessionID
        {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    private static func contentState(from snapshot: ActiveTimerSnapshot) -> SteeprLiveActivityAttributes.ContentState {
        let remaining = snapshot.currentSecondsRemaining
        let progress: Double
        if snapshot.durationSeconds > 0 {
            progress = min(1, max(0, 1 - (Double(remaining) / Double(snapshot.durationSeconds))))
        } else {
            progress = 0
        }

        return SteeprLiveActivityAttributes.ContentState(
            state: snapshot.state.rawValue,
            endDate: snapshot.endDate,
            secondsRemaining: remaining,
            progress: progress
        )
    }
}
#else
enum LiveActivityService {
    static func start(snapshot: ActiveTimerSnapshot) {}
    static func update(snapshot: ActiveTimerSnapshot) {}
    static func end(sessionID: UUID? = nil) {}
}
#endif
