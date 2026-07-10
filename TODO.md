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

## v1.1 App Store Submission (1.1 build 3)

Code is ready. Remaining work is App Store Connect metadata, screenshots, and upload.

- [ ] Smoke-test v1.1 on a physical iPhone and paired Apple Watch (onboarding, guided re-steep, journal, search).
- [ ] Archive `Steepr` scheme in Release with version 1.1 / build 3.
- [ ] Upload build to App Store Connect and wait for processing.
- [ ] Attach build 3 to the v1.1 version in App Store Connect.
- [ ] Paste What's New copy for v1.1 (draft in release prep notes).
- [ ] Update subtitle, promotional text, and description for ASO (see `GROWTH.md`).
- [ ] Update keywords to intent-based set: `tea timer,steep timer,brew timer,tea clock,matcha timer,herbal timer,tea reminder,brewing guide,tea alarm,loose leaf`.
- [ ] Capture v1.1 iPhone screenshots from release builds (journal, re-steep completion, onboarding optional).
- [ ] Capture updated Watch screenshots if guided infusion UI changed materially.
- [ ] Reorder screenshots: brew flow first, Watch second, paywall last.
- [ ] Submit for review.

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
