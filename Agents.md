# AGENTS.md

## Project: Steepr

Steepr is a minimal, step-based tea timer built as a native macOS app using Swift and SwiftUI.

The goal is to provide a clean, distraction-free experience for timing multi-step tea workflows like boiling, cooling, and steeping.

---

## Core Principles

* Keep everything simple and intentional
* No unnecessary features or abstractions
* Prioritize clarity over cleverness
* The app should feel fast, calm, and predictable
* UI should never get in the way of the workflow

---

## Product Scope

### What Steepr does

* Lets users define tea “profiles” (sets of steps)
* Each profile consists of ordered steps with durations
* Runs steps sequentially with clear transitions
* Notifies the user when each step completes

### What Steepr does NOT do (for now)

* No accounts or cloud sync
* No social or sharing features
* No analytics or tracking
* No complex customization or theming

---

## Architecture

### High-Level Structure

* Presentation Layer: SwiftUI views
* Domain Layer: Timer logic and step sequencing
* Data Layer: Local persistence (JSON or UserDefaults)

Keep layers loosely coupled and easy to reason about.

---

## Core Concepts

### Step

A single unit of work in the tea process.

Properties:

* name (String)
* duration (in seconds)
* optional notes

---

### Profile

A collection of ordered steps.

Examples:

* Green Tea
* Black Tea
* Custom Brew

---

### Session

A running instance of a profile.

Responsibilities:

* Track current step
* Handle countdown
* Move to next step
* Trigger notifications

---

## State Management

* Use a single source of truth for the active session
* Avoid scattered timers or duplicated state
* Prefer simple observable objects over complex patterns

---

## UI Guidelines

* Minimal, clean layout
* Clear hierarchy:

  * Current step (most prominent)
  * Timer countdown
  * Upcoming steps (secondary)
* Avoid clutter and unnecessary controls
* Animations should be subtle and purposeful

---

## Notifications

* Notify when a step completes
* Optionally include step name in notification
* No excessive or repeated alerts

---

## Persistence

* Store profiles locally
* Prefer simple formats (JSON or UserDefaults)
* No database unless absolutely necessary

---

## Code Style

* Write readable, self-explanatory code
* Avoid over-engineering
* Keep functions small and focused
* Use meaningful names over comments

---

## Non-Goals

* This is not a full productivity app
* This is not a habit tracker
* This is not a smart home integration tool

---

## Future Extensions (Optional)

* Custom sounds per step
* Menu bar mode
* Keyboard shortcuts
* Import/export profiles

Only consider these after the core experience feels complete.

---

## Definition of Done

A feature is done when:

* It works reliably
* It feels intuitive without explanation
* It does not add unnecessary complexity
* It aligns with the minimal philosophy of the app

