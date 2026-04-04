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
    }
    
    func resume() {
        startTimer()
    }
    
    func stop() {
        state = .idle
        timer?.cancel()
        currentStepIndex = 0
        timeRemaining = 0
    }
    
    func skip() {
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
            notifyStepCompletion()
            nextStep()
        }
    }
    
    private func nextStep() {
        currentStepIndex += 1
        if let steps = profile?.steps, currentStepIndex < steps.count {
            setupCurrentStep()
            if state == .running {
                startTimer()
            }
        } else {
            state = .completed
            timer?.cancel()
        }
    }
    
    private func notifyStepCompletion() {
        // Guard against crashes when running without a proper app bundle
        guard Bundle.main.bundleIdentifier != nil else {
            print("Step Complete: \(currentStep?.name ?? "Unknown")")
            return
        }
        
        guard let step = currentStep else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Step Complete"
        content.body = "\(step.name) is done!"
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    func formattedTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}
