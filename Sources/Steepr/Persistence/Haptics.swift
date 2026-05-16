import Foundation
import SwiftUI
import AudioToolbox

#if os(iOS)
import UIKit
#endif

#if os(macOS)
import AppKit
#endif

class Haptics {
    static let shared = Haptics()

    func playCompletion(style: HapticStyle, soundEnabled: Bool) {
        switch style {
        case .standard:
            playSuccess()
        case .soft:
            playImpact()
        case .strong:
            playStrongCompletion()
        }

        if soundEnabled {
            playCompletionSound()
        }
    }
    
    func playSuccess() {
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #elseif os(macOS)
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
        #endif
    }
    
    func playWarning() {
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
        #elseif os(macOS)
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
        #endif
    }
    
    func playImpact() {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        #elseif os(macOS)
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
        #endif
    }
    
    func playCompletionSound() {
        #if os(iOS)
        AudioServicesPlaySystemSound(1005) // Standard notification sound
        #elseif os(macOS)
        AudioServicesPlaySystemSound(1013) // 'Glass' or standard ping on Mac
        #endif
    }

    private func playStrongCompletion() {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            generator.impactOccurred()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            generator.impactOccurred()
        }
        #elseif os(macOS)
        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
        #endif
    }
}
