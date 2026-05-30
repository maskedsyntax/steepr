# Steepr TODO

This list tracks the remaining app work against `spec.md`. Keep each step small and shippable.

## Core Foundation

- [x] iPhone tab structure: Brew, Library, Settings.
- [x] Built-in tea library, favorites, and custom teas.
- [x] Single active timer with pause, resume, cancel, completion, and restore after relaunch.
- [x] Local notifications with completion and pre-alert support.
- [x] Brew history for completed and cancelled sessions.
- [x] StoreKit Pro purchase, restore, and clear purchase status UI.
- [x] Move active timer state into an app-group-backed shared snapshot.
- [x] Move favorite teas into an app-group-backed shared snapshot.
- [x] Move preferences into an app-group-backed shared snapshot.
- [x] Add App Group entitlements in the Xcode project once extension targets are created.

## iPhone V1 Completion

- [x] Finish first-launch onboarding: welcome, starter favorites, notification prompt.
- [x] Add explicit notification permission status actions in Settings.
- [x] Add support/privacy links that point to final production URLs.
- [x] Remove non-essential acknowledgments and maker attribution from Settings.
- [x] Audit Dynamic Type, VoiceOver labels, Reduce Motion, and color-blind behavior.
- [x] Set up committed localization resources.
- [x] Finish migrating runtime-generated strings into localization resources.

## Apple Watch

- [x] Add watchOS Swift target and shared model files.
- [x] Build Watch root quick-start favorites list.
- [x] Build Watch active timer view with pause and cancel.
- [x] Add iPhone-side WatchConnectivity sync for favorites and settings.
- [x] Consume synced favorites and settings in the Watch app.
- [x] Add completion and pre-alert haptics on Watch.

## Widgets, Live Activities, and Complications

- [x] Add WidgetKit extension.
- [x] Add Quick Brew widget with interactive tea buttons.
- [x] Add Current Brew widget that reads the shared active timer snapshot.
- [x] Add Live Activity and Dynamic Island layouts.
- [x] Add interactive pause/cancel intents for widgets and Live Activities.
- [x] Add Watch complications for circular, corner, and rectangular families.

## Persistence and Sync

- [x] Decide on final persistence architecture: SwiftData for durable app data, JSON/App Group snapshots only for widgets, Watch, and Live Activities.
- [x] Migrate durable local data from JSON storage to SwiftData before v1.
- [x] Seed built-in teas into SwiftData and preserve existing user data during migration.
- [x] Add Pro-only CloudKit sync after the SwiftData model is stable.
- [x] Keep active timers local-only even when CloudKit sync is enabled.

## App Store Readiness

- [x] Add StoreKit configuration for local purchase testing.
- [x] Verify product ID `com.steepr.app.pro` in App Store Connect.
- [x] Add production App Group, iCloud, notification, and in-app purchase capabilities.
- [x] Add Apple Developer team signing settings for the iOS app and widget targets.
- [x] Add privacy manifest files for the app and widget targets.
- [x] Declare required-reason API usage for App Group `UserDefaults` access.
- [x] Enable Live Activities in the iOS app Info.plist with `NSSupportsLiveActivities`.
- [x] Decide whether v1 is iPhone-only or universal iPhone/iPad: v1 is iPhone-only, per `spec.md`.
- [x] If v1 is iPhone-only, remove iPad from `TARGETED_DEVICE_FAMILY`; otherwise prepare iPad screenshots and QA.
- [x] Decide whether Apple Watch ships in v1: Watch ships in v1, per `spec.md`.
- [x] If Watch does not ship in v1, remove Watch-facing onboarding, settings, support, and marketing copy: not required because Watch ships in v1.
- [x] Verify final 1024x1024 app icon asset.
- [ ] Capture final App Store screenshots from release builds.
- [ ] Capture required iPhone screenshots for App Store Connect.
- [x] Capture required iPad screenshots if the app remains universal: not required for iPhone-only v1.
- [x] Create privacy policy and marketing site content.
- [ ] Publish production privacy policy and support URLs.
- [x] Run unsigned Release build.
- [ ] Run signed archive validation.
- [ ] Run device and TestFlight QA.

## Deferred After V1

- [x] Re-steep support.
- [ ] Caffeine estimates.
- [ ] Brew journal notes and ratings.
- [ ] Tea packaging scanner.
- [ ] Advanced import/export.
