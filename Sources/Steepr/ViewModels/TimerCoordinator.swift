import Combine
import Foundation
import UserNotifications

#if canImport(WidgetKit)
import WidgetKit
#endif

enum ActiveTimerState: String, Codable, Equatable {
    case idle
    case running
    case paused
    case completed
}

final class TimerCoordinator: ObservableObject {
    static var notificationsEnabled = true
    private static let sharedTimerDidChangeNotification = "com.maskedsyntax.steepr.sharedTimerDidChange"

    @Published private(set) var activeTea: Tea?
    @Published private(set) var state: ActiveTimerState = .idle
    @Published private(set) var secondsRemaining = 0
    @Published private(set) var durationSeconds = 0
    @Published private(set) var currentSessionID = UUID()
    @Published private(set) var startedAt: Date?
    @Published private(set) var infusionNumber = 1

    private var timer: AnyCancellable?
    private var endDate: Date?
    private var pausedRemainingSeconds = 0
    private var completionHapticStyle: HapticStyle = .standard
    private var completionSoundEnabled = true
    private var hasRestoredPersistedTimer = false
    private let notificationIdentifier = "steepr.brew.complete"
    private let preAlertIdentifier = "steepr.brew.pre-alert"

    init() {
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            Unmanaged.passUnretained(self).toOpaque(),
            { _, observer, _, _, _ in
                guard let observer else { return }
                let coordinator = Unmanaged<TimerCoordinator>.fromOpaque(observer).takeUnretainedValue()
                Task { @MainActor in
                    coordinator.reloadFromSharedTimer(preferences: TimerCoordinator.loadSharedPreferences())
                }
            },
            Self.sharedTimerDidChangeNotification as CFString,
            nil,
            .deliverImmediately
        )
    }

    deinit {
        CFNotificationCenterRemoveObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            Unmanaged.passUnretained(self).toOpaque(),
            CFNotificationName(Self.sharedTimerDidChangeNotification as CFString),
            nil
        )
    }

    var progress: Double {
        guard durationSeconds > 0 else { return 0 }
        return 1 - (Double(secondsRemaining) / Double(durationSeconds))
    }

    func start(_ tea: Tea, preferences: UserPreferences) {
        start(tea, preferences: preferences, infusionNumber: 1)
    }

    private func start(_ tea: Tea, preferences: UserPreferences, infusionNumber: Int) {
        cancel()
        let duration = tea.steepSeconds(forInfusion: infusionNumber, proPurchased: preferences.proPurchased)
        activeTea = tea
        currentSessionID = UUID()
        startedAt = Date()
        self.infusionNumber = max(1, infusionNumber)
        completionHapticStyle = preferences.hapticStyle
        completionSoundEnabled = preferences.soundEnabled
        durationSeconds = duration
        secondsRemaining = duration
        endDate = Date().addingTimeInterval(TimeInterval(duration))
        state = .running
        scheduleNotifications(for: tea, preferences: preferences, durationSeconds: duration)
        persistTimer()
        startTicker()
    }

    func restoreIfNeeded(preferences: UserPreferences) {
        guard !hasRestoredPersistedTimer else { return }
        hasRestoredPersistedTimer = true

        restorePersistedTimer(preferences: preferences, cancelWhenMissing: false)
    }

    func reloadFromSharedTimer(preferences: UserPreferences) {
        restorePersistedTimer(preferences: preferences, cancelWhenMissing: activeTea != nil)
    }

    private func restorePersistedTimer(preferences: UserPreferences, cancelWhenMissing: Bool) {

        guard
            let data = AppGroup.userDefaults.data(forKey: ActiveTimerSnapshot.storageKey),
            let snapshot = try? JSONDecoder().decode(ActiveTimerSnapshot.self, from: data)
        else {
            if cancelWhenMissing {
                cancel(scheduleNotification: false)
            }
            return
        }

        timer?.cancel()
        activeTea = snapshot.tea
        currentSessionID = snapshot.sessionID
        startedAt = snapshot.startedAt
        completionHapticStyle = snapshot.hapticStyle
        completionSoundEnabled = snapshot.soundEnabled
        durationSeconds = snapshot.durationSeconds
        endDate = snapshot.endDate
        pausedRemainingSeconds = snapshot.pausedRemainingSeconds
        infusionNumber = snapshot.infusionNumber
        state = snapshot.state

        switch snapshot.state {
        case .idle:
            cancel()
        case .paused:
            secondsRemaining = max(0, snapshot.pausedRemainingSeconds)
            LiveActivityService.update(snapshot: snapshot)
        case .running:
            refreshRemaining()
            if secondsRemaining <= 0 {
                complete(playFeedback: false)
            } else {
                scheduleNotifications(for: snapshot.tea, preferences: preferences, durationSeconds: snapshot.durationSeconds)
                LiveActivityService.update(snapshot: snapshot)
                startTicker()
            }
        case .completed:
            secondsRemaining = 0
            LiveActivityService.update(snapshot: snapshot)
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
        scheduleNotifications(for: tea, preferences: preferences, durationSeconds: durationSeconds)
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
        infusionNumber = 1
        completionHapticStyle = .standard
        completionSoundEnabled = true
        clearPersistedTimer()
        LiveActivityService.end(sessionID: sessionID)
    }

    func brewAgain(preferences: UserPreferences) {
        guard let tea = activeTea else { return }
        start(tea, preferences: preferences, infusionNumber: 1)
    }

    func reSteep(preferences: UserPreferences) {
        guard let tea = activeTea else { return }
        start(tea, preferences: preferences, infusionNumber: infusionNumber + 1)
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

    private func scheduleNotifications(for tea: Tea, preferences: UserPreferences, durationSeconds: Int) {
        removeNotifications()
        guard Self.notificationsEnabled, Bundle.main.bundleIdentifier != nil, secondsRemaining > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = L10n.teaReady(tea.name)
        content.body = L10n.steepedForTapToReSteep(formattedDuration(durationSeconds))
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
            pausedRemainingSeconds: pausedRemainingSeconds,
            infusionNumber: infusionNumber
        )

        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        AppGroup.userDefaults.set(data, forKey: ActiveTimerSnapshot.storageKey)
        reloadCurrentBrewWidget()
        if state == .running, snapshot.secondsRemaining == snapshot.durationSeconds {
            LiveActivityService.start(snapshot: snapshot)
        } else {
            LiveActivityService.update(snapshot: snapshot)
        }
    }

    private func clearPersistedTimer() {
        AppGroup.userDefaults.removeObject(forKey: ActiveTimerSnapshot.storageKey)
        reloadCurrentBrewWidget()
    }

    private func reloadCurrentBrewWidget() {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: "com.steepr.current-brew")
        #endif
    }

    private static func loadSharedPreferences() -> UserPreferences {
        guard
            let data = AppGroup.userDefaults.data(forKey: UserPreferencesSnapshot.storageKey),
            let snapshot = try? JSONDecoder().decode(UserPreferencesSnapshot.self, from: data)
        else {
            return .defaults
        }

        return snapshot.preferences
    }
}
