import Combine
import Foundation
import UserNotifications

enum ActiveTimerState: Equatable {
    case idle
    case running
    case paused
    case completed
}

final class TimerCoordinator: ObservableObject {
    @Published private(set) var activeTea: Tea?
    @Published private(set) var state: ActiveTimerState = .idle
    @Published private(set) var secondsRemaining = 0
    @Published private(set) var durationSeconds = 0

    private var timer: AnyCancellable?
    private var endDate: Date?
    private var pausedRemainingSeconds = 0
    private let notificationIdentifier = "steepr.brew.complete"
    private let preAlertIdentifier = "steepr.brew.pre-alert"

    var progress: Double {
        guard durationSeconds > 0 else { return 0 }
        return 1 - (Double(secondsRemaining) / Double(durationSeconds))
    }

    func start(_ tea: Tea, preferences: UserPreferences) {
        cancel(scheduleNotification: false)
        activeTea = tea
        durationSeconds = tea.steepSeconds
        secondsRemaining = tea.steepSeconds
        endDate = Date().addingTimeInterval(TimeInterval(tea.steepSeconds))
        state = .running
        scheduleNotifications(for: tea, preferences: preferences)
        startTicker()
    }

    func pause() {
        guard state == .running else { return }
        refreshRemaining()
        pausedRemainingSeconds = secondsRemaining
        state = .paused
        endDate = nil
        timer?.cancel()
        removeNotifications()
    }

    func resume(preferences: UserPreferences) {
        guard let tea = activeTea, state == .paused, pausedRemainingSeconds > 0 else { return }
        secondsRemaining = pausedRemainingSeconds
        endDate = Date().addingTimeInterval(TimeInterval(pausedRemainingSeconds))
        state = .running
        scheduleNotifications(for: tea, preferences: preferences)
        startTicker()
    }

    func cancel(scheduleNotification: Bool = true) {
        timer?.cancel()
        if scheduleNotification {
            removeNotifications()
        }
        activeTea = nil
        state = .idle
        secondsRemaining = 0
        durationSeconds = 0
        endDate = nil
        pausedRemainingSeconds = 0
    }

    func brewAgain(preferences: UserPreferences) {
        guard let tea = activeTea else { return }
        start(tea, preferences: preferences)
    }

    func done() {
        cancel()
    }

    func formattedTime(_ seconds: Int? = nil) -> String {
        let value = max(0, seconds ?? secondsRemaining)
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
        state = .completed
        endDate = nil
        Haptics.shared.playSuccess()
        Haptics.shared.playCompletionSound()
    }

    private func scheduleNotifications(for tea: Tea, preferences: UserPreferences) {
        removeNotifications()
        guard Bundle.main.bundleIdentifier != nil, secondsRemaining > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Your \(tea.name) is ready"
        content.body = "Steeped for \(formattedDuration(tea.steepSeconds)). Tap to brew again."
        content.sound = preferences.soundEnabled ? .default : nil
        content.threadIdentifier = "brew-timer"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(secondsRemaining), repeats: false)
        let request = UNNotificationRequest(identifier: notificationIdentifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)

        if let preAlertSeconds = preferences.preAlertSeconds, secondsRemaining > preAlertSeconds {
            let preContent = UNMutableNotificationContent()
            preContent.title = "\(preAlertSeconds) seconds left"
            preContent.body = "\(preAlertSeconds) seconds left on your \(tea.name)."
            preContent.threadIdentifier = "brew-timer"

            let preTrigger = UNTimeIntervalNotificationTrigger(
                timeInterval: TimeInterval(secondsRemaining - preAlertSeconds),
                repeats: false
            )
            let preRequest = UNNotificationRequest(identifier: preAlertIdentifier, content: preContent, trigger: preTrigger)
            UNUserNotificationCenter.current().add(preRequest)
        }
    }

    private func removeNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
            notificationIdentifier,
            preAlertIdentifier
        ])
    }

    private func formattedDuration(_ seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds) seconds"
        }

        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        if remainingSeconds == 0 {
            return minutes == 1 ? "1 minute" : "\(minutes) minutes"
        }
        return "\(minutes) min \(remainingSeconds) sec"
    }
}
