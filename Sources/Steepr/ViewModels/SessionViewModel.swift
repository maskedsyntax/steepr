import Foundation
import Combine
import UserNotifications

enum SessionState {
    case idle
    case running
    case paused
    case completed
}

class SessionViewModel: ObservableObject {
    @Published var profile: Profile?
    @Published var currentStepIndex: Int = 0
    @Published var timeRemaining: TimeInterval = 0
    @Published var state: SessionState = .idle
    
    private var timer: AnyCancellable?
    private var lastBackgroundDate: Date?
    
    init() {
        setupLifecycleObservers()
    }
    
    private func setupLifecycleObservers() {
        #if os(iOS)
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { [weak self] _ in
            self?.lastBackgroundDate = Date()
        }
        
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] _ in
            self?.handleForeground()
        }
        #endif
    }
    
    private func handleForeground() {
        guard let backgroundDate = lastBackgroundDate, state == .running else { return }
        let elapsed = Date().timeIntervalSince(backgroundDate)
        lastBackgroundDate = nil
        
        if elapsed >= timeRemaining {
            // Multiple steps might have passed, but for simplicity let's just finish current or move to next
            timeRemaining = 0
            tick()
        } else {
            timeRemaining -= elapsed
        }
    }
    
    var currentStep: Step? {
        guard let steps = profile?.steps, currentStepIndex < steps.count else { return nil }
        return steps[currentStepIndex]
    }
    
    var progress: Double {
        guard let duration = currentStep?.duration, duration > 0 else { return 1.0 }
        return 1.0 - (timeRemaining / duration)
    }
    
    func start(with profile: Profile) {
        self.profile = profile
        self.currentStepIndex = 0
        setupCurrentStep()
        startTimer()
    }
    
    func pause() {
        state = .paused
        timer?.cancel()
        cancelNotifications()
    }
    
    func resume() {
        startTimer()
    }
    
    func stop() {
        state = .idle
        timer?.cancel()
        cancelNotifications()
        currentStepIndex = 0
        timeRemaining = 0
    }
    
    func skip() {
        cancelNotifications()
        nextStep()
    }
    
    private func setupCurrentStep() {
        guard let step = currentStep else {
            state = .completed
            return
        }
        
        timeRemaining = step.duration
        if step.duration == 0 {
            // Handle instant steps (e.g. Boil water) - they might need manual "Next"
            // For now, let's treat them as manual steps.
            state = .idle
        } else {
            state = .running
        }
    }
    
    private func startTimer() {
        guard timeRemaining > 0 else {
            nextStep()
            return
        }
        
        state = .running
        scheduleNotification()
        
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }
    
    private func tick() {
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            nextStep()
        }
    }
    
    private func nextStep() {
        currentStepIndex += 1
        if let steps = profile?.steps, currentStepIndex < steps.count {
            Haptics.shared.playImpact()
            setupCurrentStep()
            if state == .running {
                startTimer()
            }
        } else {
            state = .completed
            timer?.cancel()
            cancelNotifications()
            Haptics.shared.playSuccess()
            Haptics.shared.playCompletionSound()
        }
    }
    
    private func scheduleNotification() {
        guard let step = currentStep, timeRemaining > 0 else { return }
        
        // Guard against crashes when running without a proper app bundle
        guard Bundle.main.bundleIdentifier != nil else {
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Step Complete"
        content.body = "\(step.name) is done!"
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeRemaining, repeats: false)
        let request = UNNotificationRequest(identifier: "steepr.step.complete", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func cancelNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["steepr.step.complete"])
    }
    
    func formattedTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}
