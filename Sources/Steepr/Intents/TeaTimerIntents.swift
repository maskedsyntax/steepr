import AppIntents
import Foundation

struct StartTeaTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Tea Timer"
    static var description = IntentDescription("Starts a steepr timer for the selected tea.")
    static var openAppWhenRun = false

    @Parameter(title: "Tea")
    var tea: TeaEntity

    init() {}

    init(tea: TeaEntity) {
        self.tea = tea
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let store = TeaStore()
        guard let teaID = tea.uuid, let selectedTea = store.tea(with: teaID) else {
            return .result(dialog: "I couldn't find that tea.")
        }

        let coordinator = TimerCoordinator()
        coordinator.start(selectedTea, preferences: store.preferences)

        return .result(dialog: "\(selectedTea.name) is steeping for \(formatIntentDuration(selectedTea.steepSeconds)).")
    }
}

struct PauseTeaTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Pause Tea Timer"
    static var description = IntentDescription("Pauses the active steepr timer.")
    static var openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let store = TeaStore()
        let coordinator = TimerCoordinator()
        coordinator.restoreIfNeeded(preferences: store.preferences)

        guard coordinator.state == .running, let tea = coordinator.activeTea else {
            return .result(dialog: "No tea timer is running.")
        }

        coordinator.pause()
        return .result(dialog: "Paused \(tea.name).")
    }
}

struct StopTeaTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Stop Tea Timer"
    static var description = IntentDescription("Cancels the active steepr timer.")
    static var openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let store = TeaStore()
        let coordinator = TimerCoordinator()
        coordinator.restoreIfNeeded(preferences: store.preferences)

        guard let tea = coordinator.activeTea else {
            return .result(dialog: "No tea timer is active.")
        }

        coordinator.cancel()
        return .result(dialog: "Stopped \(tea.name).")
    }
}

struct BrewQuickIntent: AppIntent {
    static var title: LocalizedStringResource = "Brew Quick"
    static var description = IntentDescription("Starts a steepr timer for a favorite tea.")
    static var openAppWhenRun = false

    @Parameter(title: "Tea")
    var tea: TeaEntity

    init() {}

    init(tea: TeaEntity) {
        self.tea = tea
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        try await StartTeaTimerIntent(tea: tea).perform()
    }
}

struct SteeprShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartTeaTimerIntent(),
            phrases: [
                "Start my \(\.$tea) timer in \(.applicationName)",
                "Brew \(\.$tea) in \(.applicationName)"
            ],
            shortTitle: "Start Tea Timer",
            systemImageName: "cup.and.saucer.fill"
        )

        AppShortcut(
            intent: PauseTeaTimerIntent(),
            phrases: [
                "Pause my tea timer in \(.applicationName)"
            ],
            shortTitle: "Pause Tea Timer",
            systemImageName: "pause.fill"
        )

        AppShortcut(
            intent: StopTeaTimerIntent(),
            phrases: [
                "Stop my tea timer in \(.applicationName)"
            ],
            shortTitle: "Stop Tea Timer",
            systemImageName: "xmark"
        )
    }
}

private func formatIntentDuration(_ seconds: Int) -> String {
    if seconds < 60 {
        return "\(seconds) seconds"
    }

    let minutes = seconds / 60
    let remainingSeconds = seconds % 60
    if remainingSeconds == 0 {
        return minutes == 1 ? "1 minute" : "\(minutes) minutes"
    }
    return "\(minutes) minutes \(remainingSeconds) seconds"
}
