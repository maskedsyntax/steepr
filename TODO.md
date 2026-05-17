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
- [x] Add acknowledgments and support/privacy links that point to final production URLs.
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

- [ ] Decide whether to keep the current JSON store for v1 or migrate to SwiftData before extensions.
- [ ] If migrating, seed built-in teas into SwiftData and preserve existing user data.
- [ ] Add Pro-only CloudKit sync after the local data model is stable.
- [ ] Keep active timers local-only even when CloudKit sync is enabled.

## App Store Readiness

- [ ] Add StoreKit configuration for local purchase testing.
- [ ] Verify product ID `com.steepr.app.pro` in App Store Connect.
- [ ] Add production App Group, iCloud, notification, and in-app purchase capabilities.
- [ ] Build final app icon and screenshots from bundled assets.
- [ ] Create privacy policy and marketing site content.
- [ ] Run release build, archive validation, and device QA.

## Deferred After V1

- [ ] Re-steep support.
- [ ] Caffeine estimates.
- [ ] Brew journal notes and ratings.
- [ ] Tea packaging scanner.
- [ ] Advanced import/export.
