# Steepr — Implementation Spec

**App name:** Steepr
**Tagline:** The perfect cup, every time.
**Platforms:** iPhone (iOS 17+), Apple Watch (watchOS 10+)
**Language:** Swift 5.9+, SwiftUI-first
**Distribution:** App Store (US/global)
**Monetization:** Free download + one-time Pro unlock (non-consumable IAP, $5.99, Family Sharing enabled)
**Developer:** Aftaab Siddiqui (individual App Store account)
**Bundle ID:** `com.steepr.app` (suggested)
**Marketing site:** https://steepr.maskedsyntax.com
**Brand color:** Tea-leaf green (#4A7C4E light / #6FA873 dark)
**Spec date:** 2026-05-16
**Spec version:** 1.1

---

## 1. Honest Critique of the Feature Set

Before designing anything, an unfiltered read on the proposal.

### What's genuinely strong

The product thesis is sound. A wrist-first tea timer is a small but real niche that Apple's own Timers app handles clumsily (no presets, no per-tea temperature guidance, no concept of re-steeps). The "calm, fast, Apple-native" positioning is the right wedge against the existing competition (Tea Time, Cup of Tea, Steeped), most of which feel dated or are subscription-bait.

The Watch-first framing is correct. Tea brewing is a one-handed, eyes-down, kitchen-or-desk moment — exactly where the Watch wins over the phone. Anchoring the design here forces discipline.

The Pro split is reasonable: iCloud sync, unlimited custom teas, advanced haptics. None of those are essential to the core loop, all of them are things power users will pay once for.

### What's overbuilt for v1

**Caffeine tracking** is the riskiest item. Doing it well requires accurate per-tea caffeine data (which varies wildly by leaf, water temp, steep time, infusion count — academic literature disagrees within a factor of 2). Doing it poorly invites 1-star reviews from people who notice the numbers are wrong. Recommend shipping it as a Pro-only "estimate" feature with explicit "approximate" labeling, or deferring to v1.1.

**Tea packaging scanner** is a moonshot. CoreML + Vision text recognition can read a label, but mapping arbitrary brand language ("Organic Sencha First Flush 2024") to a brewing profile is its own product. Cut from v1, keep on roadmap.

**Brew Journal** is feature creep. It pulls the app from "calm utility" toward "lifestyle app." Defer.

**Smart Temperature Assistance** ("water is too hot for green tea") has no input source unless the user types a temperature, which nobody will. Without a smart kettle integration, this becomes a static tip that should just live inside each tea preset, not a separate feature.

### What's missing

- **Onboarding.** Nothing in the spec covers first-launch experience. A 3-screen intro that picks 3 favorite teas and sets default units (°F/°C, minutes) is essential.
- **Units.** The spec assumes US users. Needs °F/°C toggle, and probably a region-aware default.
- **Empty states.** What does the iPhone app look like before any tea has been brewed?
- **Notifications.** Timers must fire even when the app is backgrounded or the Watch is asleep — this requires `UNUserNotificationCenter` permissions and a deliberate notification strategy.
- **What happens at timer completion on the Watch.** Does it auto-log to history? Auto-start a re-steep timer? Just dismiss?
- **Multi-timer support.** Can two teas brew at once? (Recommendation: no in v1 — adds enormous complexity for a real but rare use case.)
- **Accessibility commitments.** VoiceOver, Dynamic Type, Reduce Motion, color-blind safe palette.

### Verdict

It's a good app idea with a 70% well-shaped feature list. v1 should ruthlessly cut to: timer + presets + Watch + Live Activities + iCloud sync (Pro) + custom teas (Pro). Everything else gets parked behind a versioned roadmap. The spec below reflects that scope.

---

## 2. Product Decisions Summary

| Decision | Choice | Rationale |
|---|---|---|
| OS baseline | iOS 17 / watchOS 10 | Unlocks Observation framework, SwiftData, interactive Live Activities. Acceptable user-base trade for code simplicity. |
| UI framework | SwiftUI only | One codebase across iPhone, Watch, widgets, Live Activities. UIKit only for `UIViewControllerRepresentable` corner cases (none expected). |
| State / persistence | SwiftData (local) + CloudKit (Pro sync) | Native, no third-party deps, free backend. |
| Visual language | SF Symbols + tinted color per tea | Scales to Watch, Live Activity, Dynamic Island, complications without an asset pipeline. |
| Custom teas (free) | 3 maximum | Pushes power users to Pro without blocking casual use. |
| Custom teas (Pro) | Unlimited | Core Pro benefit. |
| Monetization | Free + one-time Pro unlock, $5.99 USD, Family Sharing on | Low-friction price for a utility; Family Sharing turns a single purchase into household goodwill at negligible revenue impact. |
| Multi-timer | Not supported in v1 | Complexity vs. value mismatch. |
| Caffeine tracking | Pro feature, v1.1 | Out of v1 scope per critique above. |
| Brew Journal, Scanner, Strength Profiles | Roadmap, not v1 | Out of v1. |
| Re-steep support | Cut to v1.1 | Core for loose-leaf fans, but deserves dedicated design. |
| Siri / App Intents | Yes, v1 | Cheap to add and a major Watch usability win. |
| Localization | EN at launch, JA/DE/FR/ZH-Hans at v1.1 | Tea has massive non-English markets. |
| Analytics | Anonymous, opt-in, TelemetryDeck | Aligns with "calm, Apple-native" positioning. |

---

## 3. Information Architecture

### 3.1 iPhone: tab bar vs. NavigationStack — decision

**Decision: TabView with 3 tabs**, not a single NavigationStack.

Rationale: a TabView communicates "here are the surfaces this app has" at a glance and matches user expectations for utility apps (Reminders, Timer, Health). A single stack would force settings and library to live behind hamburger menus, which feels dated.

### 3.2 Tab bar (iPhone)

| # | Tab | SF Symbol | Purpose |
|---|---|---|---|
| 1 | **Brew** | `cup.and.saucer.fill` | The primary surface. Live timer + quick-start grid of favorite teas. Default tab on launch. |
| 2 | **Library** | `books.vertical.fill` | Browse all built-in teas, manage custom teas, pick favorites for Watch. |
| 3 | **Settings** | `gearshape.fill` | Units, haptics, notifications, Pro upgrade, About. |

Three tabs only. A 4th tab for History/Journal would be premature given Brew Journal is roadmap.

### 3.3 Apple Watch surfaces

Watch does not use tabs. It uses a single root view (TimelineView with the active timer or quick-start grid) plus push navigation to a tea picker. Detailed below in §6.

### 3.4 Cross-surface feature placement

| Feature | iPhone | Watch | Widget | Live Activity | Complication | Siri |
|---|:-:|:-:|:-:|:-:|:-:|:-:|
| Start timer | ✓ | ✓ | ✓ | — | ✓ | ✓ |
| Active timer view | ✓ | ✓ | ✓ | ✓ | ✓ | — |
| Pause / cancel | ✓ | ✓ | ✓ (interactive widget) | ✓ (interactive) | — | ✓ |
| Tea library browse | ✓ | — (favorites only) | — | — | — | — |
| Add custom tea | ✓ | — | — | — | — | — |
| Pick Watch favorites | ✓ | — | — | — | — | — |
| Settings | ✓ | partial | — | — | — | — |
| Pro upgrade | ✓ | — | — | — | — | — |

Watch is a consumer of the favorites list, not an editor. This avoids the "tiny keyboard" problem.

---

## 4. iPhone — Screen-by-Screen

### 4.1 Tab 1: Brew

**File:** `BrewView.swift`

**States:**

1. **Idle, no active timer.** Top: large "What are you brewing?" prompt. Below: a 2-column grid of up to 6 favorite teas (SF Symbol + name + steep duration). Below the grid: a "Browse all teas" button that pushes to Library. If the user has no favorites yet: empty state with a single CTA "Pick your favorites" → opens Library.
2. **Active timer.** Hero card replaces the grid: large circular progress ring, MM:SS countdown in the center, tea name and temperature below the ring, Pause / Cancel buttons below that. The favorites grid is hidden — focus is the brew. A small "+ start another" link is *not* present in v1 (no multi-timer).
3. **Completed.** Ring fills, haptic fires, view transitions to a "Done!" state with the tea name and two buttons: "Brew again" (starts the same tea) and "Done" (returns to idle). Auto-dismisses to idle after 30s of inactivity.

**No photographs.** Each tea renders as: SF Symbol on a tinted circular background using the tea's brand color (see §5).

**Navigation:** none — Brew is a single screen, no push stack.

### 4.2 Tab 2: Library

**File:** `LibraryView.swift`

**Structure:** NavigationStack with two sections in a `List`:

1. **My Teas** — user's custom teas (free: max 3, Pro: unlimited). Each row shows symbol, name, steep time. Trailing swipe to delete. Tap to edit. Header has a "+" button to add.
2. **Built-in** — 8 hand-curated teas (Green, Black, Oolong, White, Herbal, Chai, Pu-erh, Matcha). Grouped by section header.

Each row has a leading star toggle that promotes the tea to the Watch favorites set (cap 6 — see §6.3).

**Tap on row → `TeaDetailView`** (push):

- Large symbol header
- Editable fields if custom (name, symbol picker, color picker, steep duration, temperature, caffeine estimate, notes)
- Read-only if built-in (but user can duplicate to My Teas and then edit)
- "Brew now" primary button at the bottom
- "Remove from Watch favorites" / "Add to Watch favorites" secondary

**Add tea sheet (`AddTeaSheet.swift`):**

- Form with: name (required, 1–30 chars), symbol picker (curated subset of ~24 SF Symbols filtered by `food.and.drink` category), color picker (10 preset swatches, no full color wheel — keeps the brand palette coherent), steep duration (Stepper, 0:15 to 15:00 in 15s increments), temperature (Stepper, 60–100°C / 140–212°F), optional caffeine mg (Stepper, 0–150).
- Free user with 3 customs already saved → tapping "+" shows a Pro paywall sheet.

### 4.3 Tab 3: Settings

**File:** `SettingsView.swift`

`Form` with these sections, in order:

**Steepr Pro** (top, only shown if not yet purchased)
- Marketing row with sparkle icon → opens `PaywallView` sheet.

**Brewing**
- Units: Temperature (°F / °C, region default), Time format (M:SS).
- Default steep duration: stepper (used as fallback for custom teas).
- Pre-completion alert: Toggle. Sub-row when on: 10s / 30s / 1 min before completion.

**Notifications & Haptics**
- Push notification permission status row (taps to system Settings if denied).
- Completion haptic style: Standard / Soft / Strong (Pro). Free users see a "Pro" badge on Strong.
- Sound on completion: Toggle + sound picker (3 built-in sounds).

**Watch**
- "Manage Watch favorites" row → pushes a re-orderable list of currently-favorited teas (drag handles). Edits sync to Watch via WatchConnectivity.
- Auto-start same tea on complication tap: Toggle. (When on, tapping the complication starts the last-brewed tea instead of opening the picker.)

**Pro**
- Restore purchases.
- Manage subscription (hidden — not a sub).

**About**
- Version + build.
- Privacy policy (linked URL).
- Contact support (`mailto:`).

### 4.4 Modal sheets

| Sheet | Trigger | Notes |
|---|---|---|
| `PaywallView` | Tap Pro row, attempt 4th custom tea, attempt Strong haptic | Single-screen, hero illustration (SF Symbol composition), feature bullets, $5.99 buy button, "Restore" small text link below. |
| `AddTeaSheet` | "+" in Library | See 4.2. |
| `TimerCompleteSheet` | Timer completes while Brew tab is not foreground | Optional — modal that says "Your [tea] is ready" with Brew Again / Done. |
| `OnboardingView` | First launch | 3 pages: welcome, pick 3 starter teas, notification permission prompt. |

---

## 5. Visual Design System

### 5.1 Color

Two layers:

**App chrome** — semantic system colors (`.background`, `.label`, `.secondaryLabel`). No custom UI tint at app level; respects user's system appearance.

**Tea palette** — each tea has a brand color. These 10 swatches are the only colors a custom tea can use:

| Tea / Slot | Hex (light) | Hex (dark) | Symbol (default) |
|---|---|---|---|
| Green | #4A7C4E | #6FA873 | `leaf.fill` |
| Black | #3D2817 | #6B4A33 | `cup.and.saucer.fill` |
| Oolong | #B8732F | #D89554 | `flame.fill` |
| White | #D4C5A0 | #E8DBB8 | `cloud.fill` |
| Herbal | #A8456B | #C46688 | `camera.macro` |
| Chai | #8B4513 | #B8693A | `sparkles` |
| Pu-erh | #5C3A21 | #8B5E3C | `mountain.2.fill` |
| Matcha | #7BA428 | #9DC04A | `circle.hexagongrid.fill` |
| Custom slot A | #4A5FC1 | #7388D4 | user picks |
| Custom slot B | #C14A7C | #D47394 | user picks |

Colors are defined in an Asset Catalog (`TeaColors.xcassets`) with light/dark variants. Light/dark are AA-contrast verified.

### 5.2 Typography

- Display (timer countdown): SF Pro Rounded, weight `.bold`, size 88pt on iPhone / 48pt on Watch, monospaced digits via `.monospacedDigit()`.
- Title: SF Pro, `.title`, `.semibold`.
- Body: SF Pro, `.body`, system regular.
- Caption (steep time labels): SF Pro Rounded, `.footnote`, `.medium`.

All text uses Dynamic Type and scales fully (tested at AX5).

### 5.3 Iconography

SF Symbols only, weight `.medium`, hierarchical rendering mode where supported. No raster art in the app bundle for tea icons. The only raster assets are the App Icon and one optional onboarding hero illustration.

### 5.4 Motion

- Timer ring uses `.animation(.linear(duration: 1), value: secondsRemaining)`.
- Tab transitions: system default.
- Sheet presentations: system default (`.sheet`).
- Reduce Motion respected — when on, the ring snaps in 1s steps with no easing.

### 5.5 Haptics (iPhone)

`UINotificationFeedbackGenerator` for completion (`.success`). `UIImpactFeedbackGenerator(style: .soft)` for the pre-alert. Pro users unlock a `.heavy` strong haptic and an optional 3-tap pattern at completion.

---

## 6. Apple Watch App

### 6.1 Architecture

**Standalone Watch app target** (`steeprWatch`). Communicates with iPhone via `WatchConnectivity` for one-time favorites sync, but functions fully offline with a local-only SwiftData store.

### 6.2 Root view

**File:** `WatchRootView.swift`

Two states:

1. **No active timer** — vertical scrollable list of favorite teas (max 6). Each row is a button: symbol on the left, name and steep duration stacked on the right. Digital Crown scrolls. Tap starts the timer. A "More…" row at the bottom navigates to a paged picker showing all teas the user has favorited that didn't make the visible cap, plus a "Custom timer" row that lets the user dial in any duration with the Crown.

2. **Active timer** — full-screen ring with countdown in the center, tea name above, pause/cancel under. Crown does nothing (avoids fat-finger pauses). Digital Crown is reserved for the duration picker in custom mode.

### 6.3 Why 6 favorites?

The Watch app shows 6 teas because that's the count that fits on a single Series 9 / Ultra screen without scrolling. More than 6 means scrolling, which kills the "one-tap brew" promise. Users can re-order from iPhone Settings to control which 6 appear. Built-in teas auto-fill the slots if the user has fewer than 6 favorited.

### 6.4 Complications

Three complication families shipped:

| Family | Render | Tap behavior |
|---|---|---|
| `.accessoryCircular` | Steam icon + small "Steep" label, or progress ring when timer active | Opens the Watch app to current state |
| `.accessoryCorner` | Same as circular, formatted for corner | Opens app |
| `.accessoryRectangular` | "Steeping Green Tea · 1:42" when active, otherwise "Tap to brew" | Opens app |

When a timer is active, complications display live countdown via a `TimelineProvider` that emits an entry per minute (timer countdown precision below the minute is handled by `Text(timerInterval:)` in SwiftUI, which the system updates without per-second timeline entries).

### 6.5 Haptics (Watch)

`WKInterfaceDevice.current().play(.success)` on completion. Pre-alert (if enabled) uses `.notification` 10/30/60s before the end. Strong-haptic Pro setting plays `.success` then `.notification` 0.4s later for a perceived "double-tap."

### 6.6 Always-On Display

Active-timer view supports AOD: same layout, dimmed background, ring continues to draw but with reduced motion. Achieved by using a single `Text(timerInterval:)` view that watchOS automatically dims and updates on AOD.

### 6.7 Background behavior

A running timer schedules a local `UNNotificationRequest` with a calendar trigger so completion fires even if the app is suspended. The Watch app uses `WKExtendedRuntimeSession` of type `.physicalTherapy`-equivalent? **No** — Apple does not offer a "cooking" runtime session. Instead, rely entirely on the scheduled notification + complication TimelineView. The app itself does not need to be running.

---

## 7. Data Model

### 7.1 SwiftData entities

```swift
@Model
final class Tea {
    @Attribute(.unique) var id: UUID
    var name: String
    var symbolName: String         // SF Symbol name
    var colorSlot: TeaColorSlot     // enum, maps to asset catalog color
    var steepSeconds: Int           // canonical duration
    var temperatureCelsius: Int     // canonical; UI converts
    var caffeineMilligrams: Int?    // optional, nil for herbals
    var isBuiltIn: Bool             // built-in teas are not user-deletable
    var isFavorite: Bool            // surfaces on Watch
    var favoriteRank: Int?          // user-orderable; nil if not favorited
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade) var sessions: [BrewSession] = []
}

@Model
final class BrewSession {
    @Attribute(.unique) var id: UUID
    var teaID: UUID                 // soft reference (tea may be deleted)
    var teaSnapshotName: String     // preserve name even if tea gone
    var startedAt: Date
    var completedAt: Date?
    var cancelledAt: Date?
    var actualSteepSeconds: Int     // measured, may differ from canonical
    var infusionNumber: Int         // 1 for v1; reserved for re-steep
}

@Model
final class UserPreferences {
    @Attribute(.unique) var id: UUID  // singleton, always one row
    var useCelsius: Bool
    var preAlertSeconds: Int?         // nil = off; 10/30/60
    var hapticStyle: HapticStyle      // .standard / .soft / .strong(Pro)
    var soundEnabled: Bool
    var soundName: String
    var autoStartSameTea: Bool
    var notificationsAuthorized: Bool
    var onboardingComplete: Bool
    var proPurchased: Bool             // mirror of StoreKit; not source of truth
}

enum TeaColorSlot: Int, Codable { case green, black, oolong, white, herbal, chai, puerh, matcha, customA, customB }
enum HapticStyle: Int, Codable { case standard, soft, strong }
```

### 7.2 Source of truth

- **Tea, BrewSession, UserPreferences** → SwiftData local store, scope `.private`.
- **Pro purchase state** → StoreKit 2 `Transaction.currentEntitlements`, mirrored to `UserPreferences.proPurchased` for sync coherence but never trusted for unlocks. Always re-verify via StoreKit on app launch.
- **Active timer state** → an `ActiveTimer` `@Observable` class held by `TimerCoordinator`. Persisted to `UserDefaults(suiteName: appGroupID)` so the Live Activity, widget, and Watch can read it. Stores: `teaID`, `startedAt`, `durationSeconds`, `pausedAt?`.

### 7.3 Built-in teas seed

Seeded on first launch into the SwiftData store with `isBuiltIn = true`. If a user "edits" a built-in tea, the app creates a custom copy and the original remains. Defaults:

| Tea | Steep | Temp |
|---|---|---|
| Green | 2:30 | 80°C |
| Black | 4:00 | 95°C |
| Oolong | 3:30 | 90°C |
| White | 3:00 | 75°C |
| Herbal | 5:00 | 100°C |
| Chai | 5:00 | 100°C |
| Pu-erh | 3:00 | 95°C |
| Matcha | 0:30 | 75°C |

### 7.4 Migration policy

Use SwiftData lightweight migrations for additive changes. For destructive or v2 schema reshape, write a `VersionedSchema` with an explicit migration plan. Reserved fields (`infusionNumber` on `BrewSession`) are pre-baked to avoid migrations when re-steep ships.

---

## 8. iCloud Sync (Pro)

### 8.1 Strategy

CloudKit private database, container `iCloud.com.steepr.app`. SwiftData with `cloudKitDatabase: .private(containerID)`. Sync is **opt-in via Pro**; free users get a local-only store.

### 8.2 What syncs

- All `Tea` records (built-in and custom).
- All `BrewSession` records.
- `UserPreferences` singleton.

### 8.3 What does not sync

- `ActiveTimer` — by design, a running timer belongs to one device. Avoids race conditions and the "my watch and phone both vibrated" problem.
- Pro entitlement — StoreKit handles cross-device via Apple ID, no need to sync our own flag.

### 8.4 Conflict resolution

CloudKit's last-writer-wins is acceptable for `Tea` and `UserPreferences`. `BrewSession` is append-only (no edits after completion), so conflicts are not possible.

### 8.5 Free → Pro upgrade

On purchase, the app does one-time SwiftData → CloudKit migration via re-saving all records. On Pro → free downgrade (refund or family-share revoke), local store remains; CloudKit data is untouched but no longer mirrored. UI surfaces a warning before allowing any destructive action in this state.

---

## 9. Frameworks

| Concern | Framework | Why |
|---|---|---|
| UI | SwiftUI | One codebase, modern. |
| State | Observation (`@Observable`) | Replaces `@ObservedObject`/`Combine` boilerplate. |
| Persistence | SwiftData | Native, integrates with CloudKit, ergonomic. |
| Sync | CloudKit (via SwiftData) | Free, private, Apple-ID-bound. |
| Watch ↔ Phone | WatchConnectivity | One-time favorites push, settings push. Not used for active timer. |
| Background timing | UserNotifications | Local `UNTimeIntervalNotificationTrigger` for completion. |
| Live Activities | ActivityKit | Lock Screen + Dynamic Island. |
| Widgets | WidgetKit | Home Screen + Lock Screen. |
| Complications | WidgetKit (`.accessoryCircular` etc.) | Modern complication API on watchOS 10. |
| Intents / Siri | App Intents | Replaces SiriKit; works with Shortcuts, Action Button. |
| In-app purchase | StoreKit 2 | `Transaction.currentEntitlements`, async/await. |
| Haptics (iPhone) | UIKit (`UI*FeedbackGenerator`) | No SwiftUI equivalent. |
| Haptics (Watch) | WatchKit (`WKInterfaceDevice`) | — |
| Analytics | TelemetryDeck Swift SDK | Privacy-respecting, opt-in. |

No third-party UI, networking, or persistence dependencies. Total dep count after `swift package resolve`: 1 (TelemetryDeck).

---

## 10. Live Activities & Dynamic Island

### 10.1 Activity attributes

```swift
struct BrewActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var startedAt: Date
        var endsAt: Date
        var isPaused: Bool
        var pausedRemainingSeconds: Int?
    }
    var teaName: String
    var teaSymbolName: String
    var teaColorHex: String   // resolved at start to avoid asset lookups in extension
}
```

### 10.2 Lock Screen layout

- Compact rectangle.
- Left: tea symbol on tinted disc.
- Center: name + `Text(timerInterval: start...end)` countdown.
- Right: pause button (interactive Live Activity, iOS 17+) → fires an `AppIntent` that mutates the timer.

### 10.3 Dynamic Island

- **Compact leading:** tea symbol on tint.
- **Compact trailing:** countdown timer (`Text(timerInterval:)`).
- **Expanded:**
  - Leading: symbol + name.
  - Trailing: countdown + temperature.
  - Bottom: Pause / Cancel buttons (interactive).
- **Minimal:** just the symbol on tint, used when multiple Live Activities are active (not from us, but possible).

### 10.4 Completion

Live Activity ends with a final state `endsAt: .now` and dismisses 4 seconds after, controlled with `Activity.end(dismissalPolicy: .after(.now + 4))`. A local notification fires simultaneously (covers the case where the user is on Lock Screen and has Live Activities disabled).

---

## 11. Widgets

### 11.1 iPhone widgets

| Widget | Size | Content |
|---|---|---|
| Quick Brew | small, medium | Up to 4 favorite teas as buttons; tap starts timer via `AppIntent`. Medium variant fits 6 in a 3×2 grid. |
| Current Brew | small, medium, lockscreen rectangular/circular | Live-updating countdown if a timer is active; otherwise prompt to start. |

Interactive widgets (iOS 17+) so tapping a tea immediately starts a timer without opening the app.

### 11.2 Smart Stack relevance

`TimelineEntry.relevance` is set to `.score(100)` during an active timer so the Current Brew widget rises in the Smart Stack. After completion, relevance drops to 0.

---

## 12. Siri & App Intents

### 12.1 Intents shipped in v1

| Intent | Phrase | Parameters | Result |
|---|---|---|---|
| `StartTeaTimerIntent` | "Start my green tea timer" | `tea: TeaEntity` | Begins timer, returns dialog "Your green tea is steeping for two and a half minutes." |
| `StopTeaTimerIntent` | "Stop my tea timer" | none | Cancels active timer. |
| `PauseTeaTimerIntent` | "Pause my tea timer" | none | Pauses. |
| `BrewQuickIntent` | "Brew matcha" | inferred from utterance | Same as start. |

`TeaEntity` is an `AppEntity` conforming to `IndexedEntity` so all teas appear in Spotlight and as suggestions for the iOS 17 Action Button on iPhone 15 Pro / 16 / Ultra.

### 12.2 Shortcuts app

All four intents are visible in Shortcuts with editable parameters, enabling automations like "When I tap NFC tag, start green tea."

---

## 13. Notifications

### 13.1 Permissions

Requested at end of onboarding, with rationale: "Steepr uses notifications to alert you when your tea is done — even if your screen is locked." Skippable. If denied, in-app banner on Brew tab points users to Settings.

### 13.2 Notification content

- Title: `"Your [Tea Name] is ready"`
- Body: `"Steeped for [duration]. Tap to brew again."`
- Sound: user-selected from settings.
- Category: `BREW_COMPLETE` with two actions: `BREW_AGAIN`, `DISMISS`.
- Thread identifier: `"brew-timer"` so consecutive timers don't stack.

### 13.3 Pre-alert

If enabled, a separate `UNNotificationRequest` schedules `preAlertSeconds` before completion. Body: `"30 seconds left on your [Tea Name]."`. Silent (no sound) — relies on haptic only.

---

## 14. Caffeine Tracking — DEFERRED to v1.1

Removed from v1 spec per §1 critique. When implemented:

- Lives as a fourth tab "Health" or a section in Settings → "Caffeine".
- Pro-only feature.
- Surfaces a 7-day stacked bar chart (SwiftUI Charts) with daily caffeine totals.
- Bedtime warning is a local notification scheduled relative to a user-set bedtime if total caffeine in the past 8h exceeds a threshold (default 100mg).
- Per-brew estimate = `tea.caffeineMilligrams * f(steepSeconds, infusionNumber)`. `f` is a simple linear interpolation against a per-tea max — explicitly documented as approximate.

---

## 15. Onboarding (v1, NEW — not in original spec)

3 pages, swipeable, with a "Skip" button on each.

**Page 1 — Welcome.** Logo, tagline, "Get started" button.
**Page 2 — Favorites.** "Pick 3 teas to start." Grid of all 8 built-ins. Multi-select up to 6, min 1 to proceed.
**Page 3 — Notifications & Watch.** Two stacked CTAs: "Allow notifications" (triggers system prompt), "Set up on Watch" (informational only — links to a help doc). "Done" finishes onboarding, sets `onboardingComplete = true`.

Total: under 30 seconds for the user.

---

## 16. Accessibility

### 16.1 Commitments

- **VoiceOver:** every interactive element has an `accessibilityLabel`. Timer ring announces remaining time on focus; suppressed during active countdown to avoid spam. Custom action "Pause timer" on the ring.
- **Dynamic Type:** all text scales to AX5. The timer countdown uses a fixed large size by design (it is the focal point), but body and labels respond.
- **Reduce Motion:** ring animates in discrete 1s steps with no easing.
- **Reduce Transparency:** Live Activity uses solid backgrounds.
- **Color blindness:** tea colors are paired with their SF Symbol so distinction never relies on color alone. Palette tested against deuteranopia / protanopia simulators.
- **Differentiate Without Color:** built-in vs custom rows in Library carry a glyph badge as well as a label.
- **Switch Control / Voice Control:** standard SwiftUI controls inherit this.

### 16.2 Watch accessibility

- Crown is not a primary input for any destructive action.
- Haptic-only completion option for users who disable sound.
- Larger Text watchOS setting respected.

---

## 17. Localization

### 17.1 v1

English (en-US) only. All user-facing strings in `Localizable.strings` from day 1 so v1.1 adds languages with zero code change.

### 17.2 v1.1 target languages

Japanese, Simplified Chinese, German, French, Korean. Tea is a culturally weighted product; these markets are real.

### 17.3 Conventions

- Times: `MeasurementFormatter` for "2 minutes 30 seconds" in VoiceOver; raw "2:30" in display.
- Temperatures: `MeasurementFormatter` with locale-appropriate unit.
- Tea names: built-in teas are translated; user-created custom teas remain as entered.

---

## 18. Privacy

### 18.1 Data collection

- No account required.
- No personal data leaves the device unless Pro user opts into iCloud sync (which is end-to-end CloudKit-private).
- Analytics: TelemetryDeck. App-side hashed user ID, no PII. Disclosed on the Pro paywall and in Settings → About. Opt-out toggle in Settings (default: opt-in).

### 18.2 App Privacy nutrition label

| Data type | Linked? | Tracking? | Purpose |
|---|---|---|---|
| Product Interaction (events) | No | No | App functionality, analytics |
| Crash data | No | No | App functionality |

Everything else: **not collected**.

### 18.3 ATT prompt

Not shown. We don't track.

---

## 19. Project Structure

```
steepr/
├─ steepr.xcworkspace
├─ Package.swift                            # Swift packages
├─ App/
│  ├─ steeprApp.swift                       # @main
│  ├─ ContentView.swift                     # TabView root
│  └─ AppGroup.swift                        # shared identifier constant
├─ Features/
│  ├─ Brew/
│  │  ├─ BrewView.swift
│  │  ├─ ActiveTimerView.swift
│  │  ├─ FavoritesGridView.swift
│  │  └─ TimerCoordinator.swift             # @Observable, owns ActiveTimer
│  ├─ Library/
│  │  ├─ LibraryView.swift
│  │  ├─ TeaRow.swift
│  │  ├─ TeaDetailView.swift
│  │  └─ AddTeaSheet.swift
│  ├─ Settings/
│  │  ├─ SettingsView.swift
│  │  ├─ HapticPickerView.swift
│  │  └─ ManageWatchFavoritesView.swift
│  ├─ Onboarding/
│  │  └─ OnboardingView.swift
│  └─ Paywall/
│     ├─ PaywallView.swift
│     └─ PurchaseCoordinator.swift
├─ Domain/
│  ├─ Models/                               # SwiftData @Models
│  ├─ Seeding/BuiltInTeas.swift
│  └─ Services/
│     ├─ NotificationService.swift
│     ├─ HapticService.swift
│     ├─ WatchConnectivityService.swift
│     └─ LiveActivityService.swift
├─ DesignSystem/
│  ├─ Colors/TeaColors.xcassets
│  ├─ TimerRingView.swift
│  └─ TeaIconView.swift
├─ Intents/
│  ├─ StartTeaTimerIntent.swift
│  ├─ StopTeaTimerIntent.swift
│  ├─ PauseTeaTimerIntent.swift
│  └─ TeaEntity.swift
├─ Widgets/                                 # Widget extension target
│  ├─ QuickBrewWidget.swift
│  ├─ CurrentBrewWidget.swift
│  └─ Provider.swift
├─ LiveActivity/                            # Widget extension shares
│  ├─ BrewActivityAttributes.swift
│  └─ BrewActivityView.swift
├─ steeprWatch Watch App/                   # Watch target
│  ├─ steeprWatchApp.swift
│  ├─ WatchRootView.swift
│  ├─ WatchActiveTimerView.swift
│  ├─ WatchFavoritesList.swift
│  └─ Complications/
│     ├─ CircularComplication.swift
│     ├─ CornerComplication.swift
│     └─ RectangularComplication.swift
├─ Resources/
│  ├─ Assets.xcassets
│  ├─ Localizable.strings (en)
│  └─ Info.plist
└─ Tests/
   ├─ UnitTests/
   └─ UITests/
```

### 19.1 Targets

1. `steepr` (iOS app)
2. `steeprWatch Watch App` (watchOS app, paired)
3. `steeprWidgets` (Widget extension — also hosts Live Activities)
4. `steeprIntents` (App Intents extension — optional; can also live in main app)
5. `steeprTests`
6. `steeprUITests`

### 19.2 App Group

`group.com.steepr.app` — shared `UserDefaults` and SwiftData store URL across app, widget, Live Activity, and intents extension.

---

## 20. Testing Strategy

### 20.1 Unit tests (target: 70% coverage on Domain)

- `TimerCoordinator`: start, pause, resume, cancel, complete, edge cases (background, system clock change).
- Built-in tea seeding (idempotent on multi-launch).
- SwiftData migrations (rehearse v1 → v1.1 even before v1.1 ships).
- Caffeine estimate function (when v1.1).
- Localization formatters.

### 20.2 UI tests (smoke only)

- Launch → start green tea timer → verify ring animates → cancel.
- Add custom tea → verify it appears in Library → verify Pro paywall on 4th attempt.
- Settings toggle persists across launch.

### 20.3 Manual test matrix per release

| Device | OS | Notes |
|---|---|---|
| iPhone 15 Pro | iOS 17 | Dynamic Island, Action Button |
| iPhone SE 3 | iOS 17 | Smallest screen, no Dynamic Island |
| Apple Watch Series 9 | watchOS 10 | Baseline |
| Apple Watch Ultra 2 | watchOS 10 | Action button |
| Apple Watch SE 2 | watchOS 10 | No always-on display |

### 20.4 Beta

TestFlight, internal 1 week, external 2 weeks before each App Store submission.

---

## 21. Analytics Events

Minimal, no PII. Tracked via TelemetryDeck.

| Event | Properties |
|---|---|
| `app_launched` | `is_pro: Bool`, `tea_count: Int` |
| `timer_started` | `tea_kind: String` (built-in name or "custom"), `duration_bucket: String` |
| `timer_completed` | (no props) |
| `timer_cancelled` | `elapsed_pct: Int` |
| `tea_added` | (no props) |
| `pro_paywall_shown` | `trigger: String` |
| `pro_purchased` | (no props) |
| `onboarding_completed` | (no props) |

No events for: which tea was added (privacy), what notes the user wrote, brew history.

---

## 22. Steepr Pro

### 22.1 What's behind the paywall

- iCloud sync (Tea library, sessions, prefs)
- Unlimited custom teas (free tier: 3)
- "Strong" haptic style + custom haptic pattern
- Custom completion sounds (free: 3 system; Pro: 8 total)
- Future: Brew Journal, Caffeine tracking (when shipped)

### 22.2 Pricing

- US: $5.99 one-time, non-consumable
- Tier 5 in App Store Connect
- Localized via App Store automatic pricing
- **Family Sharing: enabled** in App Store Connect product config

### 22.3 Purchase flow

1. User triggers paywall (Settings → Pro, or 4th custom tea, or Strong haptic).
2. `PaywallView` sheet appears.
3. "Buy Steepr Pro — $5.99" button calls `Product.purchase()`.
4. On success, `Transaction.finish()` and update `UserPreferences.proPurchased`.
5. On any in-flight pending transaction or family-shared entitlement detected at launch, app silently unlocks Pro. Family Sharing means a Pro purchase by any family organizer or member unlocks the app for everyone in the Family group — handled transparently by `Transaction.currentEntitlements`.

### 22.4 Restore

Settings → "Restore purchases" calls `AppStore.sync()`. Also implicitly resolves Family Sharing entitlements when an inheriting family member opens the app on a new device.

---

## 23. App Store Metadata

### 23.1 Listing

- **Name:** Steepr
- **Subtitle:** The perfect cup, every time
- **Seller:** Aftaab Siddiqui
- **Primary category:** Food & Drink
- **Secondary category:** Lifestyle
- **Keywords:** tea, timer, brew, matcha, chai, oolong, green tea, steep, watch
- **Support URL:** https://steepr.maskedsyntax.com/support
- **Marketing URL:** https://steepr.maskedsyntax.com
- **Privacy Policy URL:** https://steepr.maskedsyntax.com/privacy
- **Copyright:** © 2026 Aftaab Siddiqui

### 23.2 Description (draft)

> Steepr is a calm, fast tea timer built for Apple Watch and iPhone.
>
> Pick a tea. Tap once. Brew the perfect cup — every time.
>
> ◦ Hand-picked presets for green, black, oolong, white, herbal, chai, pu-erh, and matcha
> ◦ Wrist-first design with Watch complications and one-tap brewing
> ◦ Live Activities and Dynamic Island for at-a-glance countdowns
> ◦ Quick-brew widgets and Lock Screen shortcuts
> ◦ Siri support: "Hey Siri, start my green tea"
>
> Upgrade to Steepr Pro for unlimited custom teas, iCloud sync across devices, and advanced haptics.
>
> No accounts. No ads. No tracking. Just tea.

### 23.3 Screenshots (per device)

iPhone 6.7" (10 required): Brew tab idle, active timer hero, Library, tea detail, Add tea, Settings, Paywall, Live Activity on Lock Screen, Dynamic Island expanded, Watch + iPhone pair shot.

Watch (5 required): root favorites list, active timer ring, complication on watch face (3 styles).

### 23.4 What's New (v1.0)

> Welcome to Steepr — a wrist-first tea timer designed for the Apple ecosystem. We can't wait to brew with you.

### 23.5 Brand assets

- **App Icon:** provided by founder. Master at 1024×1024 PNG, sRGB, no alpha, no transparency, no rounded corners (App Store applies the mask). Generate the full Xcode icon set via Asset Catalog `AppIcon` slot — Xcode 15 only requires the 1024 master and auto-renders the smaller sizes at build.
- **Tinted icon variant (iOS 18 prep):** also supply a monochrome `AppIcon-Tinted` for the "Tinted" Home Screen mode users can opt into.
- **Brand color (system-wide):** Tea-leaf green, asset name `BrandGreen` (#4A7C4E light / #6FA873 dark) — used for primary call-to-action buttons, the Pro paywall hero, the app icon background, and the marketing site primary color.

---

## 23A. Marketing Site — steepr.maskedsyntax.com

A single-page marketing site is required for the App Store submission (privacy and support URLs are mandatory). Recommend shipping a minimal version at launch and iterating.

### 23A.1 Pages / routes

| Path | Purpose | Required by |
|---|---|---|
| `/` | Landing page — hero, features, screenshots, App Store badge, Pro pitch | Marketing |
| `/privacy` | Privacy policy | App Store submission |
| `/support` | Contact + FAQ | App Store submission |
| `/press` | Press kit (logo, screenshots, fact sheet) | Future, optional |

### 23A.2 Landing page sections (top to bottom)

1. **Hero** — App icon, "Steepr — The perfect cup, every time.", "Available on the App Store" badge, one-line tagline.
2. **The wrist-first promise** — single sentence + Watch screenshot.
3. **Feature grid** — 6 cards: presets, Live Activities, complications, Siri, widgets, Pro sync. SF Symbol illustrations matching the in-app palette.
4. **Steepr Pro** — price ($5.99 one-time), Family Sharing badge, bullet list of Pro benefits, second App Store CTA.
5. **Privacy first** — "No accounts. No ads. No tracking." paragraph + link to /privacy.
6. **Footer** — © 2026 Aftaab Siddiqui · Privacy · Support · Press.

### 23A.3 Tech recommendation

Static site, no backend. Astro or plain HTML + Tailwind, deployed to Cloudflare Pages or Vercel from a `steepr-site` GitHub repo. ~1 day of work. Same `BrandGreen` color tokens as the app so screenshots feel native to the page.

### 23A.4 Privacy policy content (skeleton)

Must cover, at minimum: what is collected (anonymous analytics events, opt-in), what is not (no PII, no contacts, no location), where data lives (on-device + optional CloudKit private for Pro), retention, user rights, contact email. Generate via a privacy policy template (e.g., termly.io or iubenda) and customize — do not write from scratch.

### 23A.5 Support page content

- "How do I…" FAQ — 10 entries covering top usage questions and the Pro purchase / restore flow.
- Contact form OR a `mailto:` link to a support address on the maskedsyntax.com domain.
- Link back to the App Store listing.

---

## 24. Release Plan

### 24.1 v1.0 — Launch

Everything in this spec. Target ship: 12 weeks from project start.

### 24.2 v1.1 — Tea fans

- Re-steep tracking (multi-infusion sessions, adaptive durations)
- Caffeine tracking (Pro)
- 4 additional localizations
- Quick Brew Presets (per-tea favorite strengths)

### 24.3 v1.2 — Intelligence

- Brew Strength Profiles
- Smart Temperature Assistance (static guidance per tea, no hardware)

### 24.4 v2.0 — Journal

- Brew Journal (ratings, notes, photos)
- Optional CSV export
- Apple Health integration for caffeine logs

### 24.5 Backlog / not committed

- Tea Packaging Scanner (CoreML training cost too high until evidence of demand)
- Smart kettle integrations
- iPad-optimized layout (currently shows iPhone layout, which is acceptable)

---

## 25. Resolved Decisions (formerly Open Questions)

All founder-level decisions are now locked.

1. **Brand color:** Tea-leaf green. Asset name `BrandGreen`, hex #4A7C4E light / #6FA873 dark. Used app-wide and on the marketing site.
2. **App Icon:** Founder-provided. Drop the 1024×1024 master into the `AppIcon` slot of `Assets.xcassets`; supply a monochrome variant for iOS 18 Tinted mode.
3. **Marketing site:** steepr.maskedsyntax.com. Routes and content defined in §23A. Must be live before App Store submission (privacy + support URLs are mandatory).
4. **Developer account:** Individual — Aftaab Siddiqui. Apple Developer Program enrollment required ($99/yr). Seller name will display as "Aftaab Siddiqui" on the App Store listing.
5. **Pricing:** $5.99 one-time, Tier 5. Family Sharing enabled at the IAP product level.

---

## 26. Definition of Done — v1.0

- All screens in §4 and §6 implemented and reachable.
- Active timer survives: app backgrounded, app force-killed (notification still fires), device reboot (notification persists in pending queue), AirPlane mode toggle.
- Watch app functions with iPhone powered off.
- Live Activity, Dynamic Island, widgets all show identical state.
- Pro purchase + restore + family-share entitlement all unlock features.
- VoiceOver runs the full happy path with no orphaned controls.
- No crashes on the manual test matrix.
- Privacy policy and support URL live.
- App Store submission accepted on first review (target).

---

*End of spec. Version 1.0 — 2026-05-16.*
