# Steepr App Store & iPhone Readiness Plan - COMPLETED

This plan outlines the steps required to port Steepr to iPhone and enhance its functionality to ensure it meets Apple's App Store guidelines while maintaining its core simplicity and **strict native-only implementation**.

## Phase 1: Multi-platform Foundation
*Goal: Decouple macOS-specific code and ensure the app runs on both iOS and macOS using native SwiftUI primitives.*

- [x] **Native Platform Abstraction:** 
    - Wrap macOS-specific logic in `SteeprApp.swift` (activation policy, icon handling) with `#if os(macOS)`.
    - Replace or conditionally compile `VisualEffectView` (currently using `NSViewRepresentable`). Use SwiftUI's native `.background(.ultraThinMaterial)` for a consistent native look on both platforms.
    - Update `ProfileStore` to use native `FileManager` URLs that are valid for both iOS (Documents directory) and macOS (Application Support).
- [x] **Responsive Native UI:**
    - Remove hardcoded `frame()` constraints on `ContentView` and `ProfileEditView`.
    - Use native `NavigationSplitView` patterns that adapt automatically: Sidebar on iPad/Mac, Tab Bar or Navigation Stack on iPhone.
- [x] **Asset Management:** Use standard `Assets.xcassets` for app icons and system symbols to ensure proper rendering across all resolutions.

## Phase 2: Increasing App Store Value (Guideline 4.2)
*Goal: Add "Smart" features to differentiate Steepr while keeping the interface clean and native.*

- [x] **Native Temperature Support:**
    - Add `temperature: Double?` and `temperatureUnit: UnitTemperature` to the `Step` model.
    - Update `ProfileEditView` with a native `Picker` for temperature settings.
- [x] **Curated Tea Library:**
    - Expand default profiles with professional brewing parameters for various tea types.
    - Add native Info Buttons to explain brewing science.
- [x] **Brewing Journal:**
    - Added a complete "History" feature with ratings, notes, and a dedicated History view.

## Phase 3: iPhone UI/UX Optimization
*Goal: Make the app feel like a first-party Apple app on iOS.*

- [x] **Native Mobile Experience:**
    - Optimize `TimerView` for portrait mode with large, accessible touch targets.
    - Integrate `UIImpactFeedbackGenerator` (iOS) and `HapticFeedback` (macOS) for tactile events.
- [x] **Native Interruptions:**
    - Use `UNUserNotificationCenter` with scheduled triggers for reliable background alerts.

## Phase 4: Robustness & Edge Cases
*Goal: Ensure the app is "bulletproof" and behaves predictably in all scenarios.*

- [x] **Lifecycle Management:**
    - Handle app backgrounding/foregrounding with timestamp-based timer accuracy.
- [x] **Data Integrity:**
    - Robust error handling for JSON encoding/decoding with atomic writes.
- [x] **UI Edge Cases:**
    - Native support for Dark Mode, Dynamic Type, and accessibility labels.

## Phase 5: Final Polish & Submission Prep
*Goal: Professionalize for the App Store.*

- [x] **Settings View:** Integrated units and notification settings into the native UI.
- [x] **iCloud Sync:** Implemented native `NSUbiquitousKeyValueStore` for cross-device profile syncing.
- [x] **QA & Validation:** Code refactored and verified for multi-platform robustness.
