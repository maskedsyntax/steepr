import Combine
import Foundation
import UserNotifications

enum ActiveTimerState: String, Codable, Equatable {
    case idle
    case running
    case paused
    case completed
}

final class TimerCoordinator: ObservableObject {
    static var notificationsEnabled = true

    @Published private(set) var activeTea: Tea?
    @Published private(set) var state: ActiveTimerState = .idle
    @Published private(set) var secondsRemaining = 0
    @Published private(set) var durationSeconds = 0
    @Published private(set) var currentSessionID = UUID()
    @Published private(set) var startedAt: Date?

    private var timer: AnyCancellable?
    private var endDate: Date?
    private var pausedRemainingSeconds = 0
    private var completionHapticStyle: HapticStyle = .standard
    private var completionSoundEnabled = true
    private var hasRestoredPersistedTimer = false
    private let notificationIdentifier = "steepr.brew.complete"
    private let preAlertIdentifier = "steepr.brew.pre-alert"

    var progress: Double {
        guard durationSeconds > 0 else { return 0 }
        return 1 - (Double(secondsRemaining) / Double(durationSeconds))
    }

    func start(_ tea: Tea, preferences: UserPreferences) {
        cancel()
        activeTea = tea
        currentSessionID = UUID()
        startedAt = Date()
        completionHapticStyle = preferences.hapticStyle
        completionSoundEnabled = preferences.soundEnabled
        durationSeconds = tea.steepSeconds
        secondsRemaining = tea.steepSeconds
        endDate = Date().addingTimeInterval(TimeInterval(tea.steepSeconds))
        state = .running
        scheduleNotifications(for: tea, preferences: preferences)
        persistTimer()
        startTicker()
    }

    func restoreIfNeeded(preferences: UserPreferences) {
        guard !hasRestoredPersistedTimer else { return }
        hasRestoredPersistedTimer = true

        guard
            let data = AppGroup.userDefaults.data(forKey: ActiveTimerSnapshot.storageKey),
            let snapshot = try? JSONDecoder().decode(ActiveTimerSnapshot.self, from: data)
        else {
            return
        }

        activeTea = snapshot.tea
        currentSessionID = snapshot.sessionID
        startedAt = snapshot.startedAt
        completionHapticStyle = snapshot.hapticStyle
        completionSoundEnabled = snapshot.soundEnabled
        durationSeconds = snapshot.durationSeconds
        endDate = snapshot.endDate
        pausedRemainingSeconds = snapshot.pausedRemainingSeconds
        state = snapshot.state

        switch snapshot.state {
        case .idle:
            cancel()
        case .paused:
            secondsRemaining = max(0, snapshot.pausedRemainingSeconds)
        case .running:
            refreshRemaining()
            if secondsRemaining <= 0 {
                complete(playFeedback: false)
            } else {
                scheduleNotifications(for: snapshot.tea, preferences: preferences)
                startTicker()
            }
        case .completed:
            secondsRemaining = 0
        }
    }

    func pause() {
        guard state == .running else { return }
        refreshRemaining()
        pausedRemainingSeconds = secondsRemaining
        state = .paused
        endDate = nil
        timer?.cancel()
        removeNotifications()
        persistTimer()
    }

    func resume(preferences: UserPreferences) {
        guard let tea = activeTea, state == .paused, pausedRemainingSeconds > 0 else { return }
        secondsRemaining = pausedRemainingSeconds
        completionHapticStyle = preferences.hapticStyle
        completionSoundEnabled = preferences.soundEnabled
        endDate = Date().addingTimeInterval(TimeInterval(pausedRemainingSeconds))
        state = .running
        scheduleNotifications(for: tea, preferences: preferences)
        persistTimer()
        startTicker()
    }

    func cancel(scheduleNotification: Bool = true) {
        let sessionID = activeTea == nil ? nil : currentSessionID
        timer?.cancel()
        if scheduleNotification {
            removeNotifications()
        }
        activeTea = nil
        state = .idle
        secondsRemaining = 0
        durationSeconds = 0
        startedAt = nil
        endDate = nil
        pausedRemainingSeconds = 0
        completionHapticStyle = .standard
        completionSoundEnabled = true
        clearPersistedTimer()
        LiveActivityService.end(sessionID: sessionID)
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

    private func complete(playFeedback: Bool = true) {
        timer?.cancel()
        secondsRemaining = 0
        state = .completed
        endDate = nil
        persistTimer()
        if playFeedback {
            Haptics.shared.playCompletion(style: completionHapticStyle, soundEnabled: completionSoundEnabled)
        }
    }

    private func scheduleNotifications(for tea: Tea, preferences: UserPreferences) {
        removeNotifications()
        guard Self.notificationsEnabled, Bundle.main.bundleIdentifier != nil, secondsRemaining > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = L10n.teaReady(tea.name)
        content.body = L10n.steepedForTapToBrewAgain(formattedDuration(tea.steepSeconds))
        content.sound = preferences.soundEnabled ? .default : nil
        content.categoryIdentifier = NotificationService.brewCompleteCategory
        content.threadIdentifier = "brew-timer"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(secondsRemaining), repeats: false)
        let request = UNNotificationRequest(identifier: notificationIdentifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)

        if let preAlertSeconds = preferences.preAlertSeconds, secondsRemaining > preAlertSeconds {
            let preContent = UNMutableNotificationContent()
            preContent.title = L10n.secondsLeft(preAlertSeconds)
            preContent.body = L10n.secondsLeftOnTea(preAlertSeconds, teaName: tea.name)
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
        guard Self.notificationsEnabled, Bundle.main.bundleIdentifier != nil else { return }
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

    private func persistTimer() {
        guard let activeTea else {
            clearPersistedTimer()
            return
        }

        let snapshot = ActiveTimerSnapshot(
            sessionID: currentSessionID,
            tea: activeTea,
            state: state,
            startedAt: startedAt ?? Date(),
            hapticStyle: completionHapticStyle,
            soundEnabled: completionSoundEnabled,
            durationSeconds: durationSeconds,
            secondsRemaining: secondsRemaining,
            endDate: endDate,
            pausedRemainingSeconds: pausedRemainingSeconds
        )

        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        AppGroup.userDefaults.set(data, forKey: ActiveTimerSnapshot.storageKey)
        if state == .running, snapshot.secondsRemaining == snapshot.durationSeconds {
            LiveActivityService.start(snapshot: snapshot)
        } else {
            LiveActivityService.update(snapshot: snapshot)
        }
    }

    private func clearPersistedTimer() {
        AppGroup.userDefaults.removeObject(forKey: ActiveTimerSnapshot.storageKey)
    }
}
