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
- [x] Create privacy policy and marketing site content.
- [x] Publish production privacy policy and support URLs.
- [x] Run unsigned Release build.
- [x] Run signed archive validation.
- [x] Run device and TestFlight QA.
- [x] Ship v1.0 on the App Store.

## v1.1 App Store Submission

- [x] Ship v1.1.0 build 8 on the App Store.
- [x] Publish refreshed metadata, screenshots, website, and support content.

## v1.2 App Store Submission

- [x] Add a repeatable Recent Brew card to the Brew tab.
- [x] Move Brew History into the Brew flow.
- [x] Expose favorite ordering from the Brew screen.
- [x] Add completed-session and favorite-order regression tests.
- [x] Update all targets to version 1.2 / build 10.
- [x] Refresh README and canonical App Store metadata.
- [x] Capture and review the new Brew Again screenshot.
- [x] Run simulator builds and the Swift test suite.
- [ ] Smoke-test on a physical iPhone and paired Apple Watch.
- [ ] Push to `master` and verify Xcode Cloud build processing.
- [ ] Stage App Store version 1.2.0 with the valid cloud build.
- [ ] Validate and submit v1.2.0 for automatic release.

## Post-v1.1 ASO (no code required)

- [ ] Ask 10–15 existing users to leave an App Store rating.
- [ ] Post a short screen-recording demo to r/tea and r/applewatch.
- [ ] Update `Marketing/home.md` App Store link from placeholder to live listing URL.

## Deferred After V1

- [x] Re-steep support.
- [ ] Caffeine estimates.
- [x] Brew journal notes and ratings.
- [ ] Tea packaging scanner.
- [ ] Advanced import/export.

## Growth Improvements

Build these in order after the v1.1 screen refresh. Keep the app tea-only.

1. [x] Improve re-steep into a real workflow.
   - Free: manual re-steep repeats the same tea duration.
   - Pro: guided multi-infusion timing that increases duration by tea type.
   - Completion screen should clearly offer the next infusion.
2. [x] Add brew journal notes and ratings.
   - Prompt after completion with a small rating and optional note.
   - Free: recent limited journal.
   - Pro: full history with notes and ratings.
3. [x] Improve completion feedback.
   - Add simple outcomes: too weak, good, too strong.
   - Use the answer to suggest a small next-time duration adjustment.
4. [x] Improve paywall triggers.
   - Trigger around guided infusions, journal limits, and meaningful usage milestones.
   - Keep prompts calm and infrequent.
5. [ ] Add 7-day Pro trial support.
   - Keep one-time purchase positioning.
   - Update paywall copy around trial and no subscription.
6. [ ] Improve Brew tab retention.
   - Add quiet summaries like today's brew count and recent tea.
   - Avoid habit-app clutter.
7. [ ] Make favorites more useful.
   - Improve reorder access.
   - Show recent brew context where useful.
8. [x] Re-enable and refresh onboarding.
   - Redesigned welcome flow with starter favorites, unit choice, notification prompt, and Watch mention.
   - Wired via first-launch full-screen cover in v1.1.
