import Combine
import Foundation
import UserNotifications

#if os(watchOS)
import WatchKit
#endif

enum WatchTimerState {
    case idle
    case running
    case paused
    case completed
}

final class WatchTimerCoordinator: ObservableObject {
    @Published private(set) var activeTea: Tea?
    @Published private(set) var state: WatchTimerState = .idle
    @Published private(set) var secondsRemaining = 0
    @Published private(set) var durationSeconds = 0

    private var timer: AnyCancellable?
    private var endDate: Date?
    private var pausedRemainingSeconds = 0
    private var preferences: UserPreferences = .defaults
    private let sharedDefaults = UserDefaults(suiteName: "group.com.maskedsyntax.Steepr") ?? .standard

    private let completionNotificationIdentifier = "steepr.watch.brew.complete"
    private let preAlertNotificationIdentifier = "steepr.watch.brew.pre-alert"

    var progress: Double {
        guard durationSeconds > 0 else { return 0 }
        return 1 - (Double(secondsRemaining) / Double(durationSeconds))
    }

    func start(_ tea: Tea, preferences: UserPreferences) {
        cancel()
        self.preferences = preferences
        activeTea = tea
        durationSeconds = tea.steepSeconds
        secondsRemaining = tea.steepSeconds
        endDate = Date().addingTimeInterval(TimeInterval(tea.steepSeconds))
        state = .running
        scheduleNotifications(for: tea)
        persistTimer()
        startTicker()
    }

    func pause() {
        guard state == .running else { return }
        refreshRemaining()
        pausedRemainingSeconds = secondsRemaining
        timer?.cancel()
        endDate = nil
        state = .paused
        removeNotifications()
        persistTimer()
    }

    func resume() {
        guard let tea = activeTea, state == .paused, pausedRemainingSeconds > 0 else { return }
        secondsRemaining = pausedRemainingSeconds
        endDate = Date().addingTimeInterval(TimeInterval(pausedRemainingSeconds))
        state = .running
        scheduleNotifications(for: tea)
        persistTimer()
        startTicker()
    }

    func cancel() {
        timer?.cancel()
        removeNotifications()
        activeTea = nil
        state = .idle
        secondsRemaining = 0
        durationSeconds = 0
        endDate = nil
        pausedRemainingSeconds = 0
        sharedDefaults.removeObject(forKey: WatchActiveTimerSnapshot.storageKey)
    }

    func brewAgain() {
        guard let tea = activeTea else { return }
        start(tea, preferences: preferences)
    }

    func done() {
        cancel()
    }

    func formattedTime() -> String {
        let value = max(0, secondsRemaining)
        return String(format: "%d:%02d", value / 60, value % 60)
    }

    private func startTicker() {
        timer?.cancel()
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    private func tick() {
        refreshRemaining()
        if secondsRemaining <= 0 {
            complete()
        }
    }

    private func refreshRemaining() {
        guard let endDate, state == .running else { return }
        secondsRemaining = max(0, Int(ceil(endDate.timeIntervalSinceNow)))
    }

    private func complete() {
        timer?.cancel()
        secondsRemaining = 0
        endDate = nil
        state = .completed
        persistTimer()
        playCompletionHaptic()
    }

    private func persistTimer() {
        guard let activeTea else {
            sharedDefaults.removeObject(forKey: WatchActiveTimerSnapshot.storageKey)
            return
        }

        let snapshot = WatchActiveTimerSnapshot(
            tea: activeTea,
            state: state.storageValue,
            durationSeconds: durationSeconds,
            secondsRemaining: secondsRemaining,
            endDate: endDate,
            pausedRemainingSeconds: pausedRemainingSeconds
        )

        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        sharedDefaults.set(data, forKey: WatchActiveTimerSnapshot.storageKey)
    }

    private func scheduleNotifications(for tea: Tea) {
        removeNotifications()
        guard secondsRemaining > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Your \(tea.name) is ready"
        content.body = "Steeped for \(formatDuration(tea.steepSeconds))."
        content.sound = preferences.soundEnabled ? .default : nil

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(secondsRemaining), repeats: false)
        let request = UNNotificationRequest(identifier: completionNotificationIdentifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)

        if let preAlertSeconds = preferences.preAlertSeconds, secondsRemaining > preAlertSeconds {
            let preContent = UNMutableNotificationContent()
            preContent.title = "\(preAlertSeconds) seconds left"
            preContent.body = "\(preAlertSeconds) seconds left on your \(tea.name)."

            let preTrigger = UNTimeIntervalNotificationTrigger(
                timeInterval: TimeInterval(secondsRemaining - preAlertSeconds),
                repeats: false
            )
            let preRequest = UNNotificationRequest(
                identifier: preAlertNotificationIdentifier,
                content: preContent,
                trigger: preTrigger
            )
            UNUserNotificationCenter.current().add(preRequest)
        }
    }

    private func removeNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
            completionNotificationIdentifier,
            preAlertNotificationIdentifier
        ])
    }

    private func playCompletionHaptic() {
        #if os(watchOS)
        WKInterfaceDevice.current().play(.success)
        if preferences.hapticStyle == .strong {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                WKInterfaceDevice.current().play(.notification)
            }
        }
        #endif
    }
}

private struct WatchActiveTimerSnapshot: Codable {
    static let storageKey = "steepr.watch.activeTimer"

    var tea: Tea
    var state: String
    var durationSeconds: Int
    var secondsRemaining: Int
    var endDate: Date?
    var pausedRemainingSeconds: Int
}

private extension WatchTimerState {
    var storageValue: String {
        switch self {
        case .idle:
            return "idle"
        case .running:
            return "running"
        case .paused:
            return "paused"
        case .completed:
            return "completed"
        }
    }
}
