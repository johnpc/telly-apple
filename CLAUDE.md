# Telly (Apple) — project charter

Telly is an open-source, TiviMate-style IPTV player for Apple platforms (iPhone,
iPad, Apple TV). Native SwiftUI. No backend of any kind. It is a port of the Android
[`telly`](https://github.com/johnpc/telly) app; that repo's charter and decisions log
are the reference for product behavior and parity.

## How we work

- **The director owns WHAT, Claude owns HOW.** Product decisions and acceptance
  criteria come from the director; architecture, implementation, and refactoring are
  Claude's call.
- **Product bar:** faithful TiviMate-style UX, ported to native SwiftUI, verified on
  the iOS/tvOS simulators and (where possible) on device / TestFlight.
- **Specs-first, vertical slices.** Every slice ships end-to-end: UI + logic + tests +
  gates green. Behavior is pinned by `.feature` acceptance specs.

## Stack

- **SwiftUI**, iOS 18 / iPadOS 18 / tvOS 18. Single universal app target
  (`TARGETED_DEVICE_FAMILY = 1,2,3`).
- **xcodegen** — `project.yml` is the source of truth; regenerate with
  `xcodegen generate`. The generated `Telly.xcodeproj` IS committed (CI reproducibility
  + parity with John's native repos).
- **Bundle id:** `com.johncorser.telly`. **Team:** JW5SC3NYUV.
- **Packages:** SWCompression (gzip/xz EPG), GRDB (SQLite persistence, mirrors the
  Android Room layer), VLCKitSPM (libVLC behind a protocol seam — IPTV serves raw
  MPEG-TS, which AVPlayer cannot decode).
- **No backend, no accounts.** Playlist/EPG URLs are user-configured; everything is
  fetched on-device and cached locally in SQLite.

## Quality gates (all must pass; "fix the code, never the gate")

Run everything with `./scripts/quality.sh`. CI and the pre-commit hook
(`core.hooksPath` via `./scripts/install-hooks.sh`) run the same checks.

| Gate | Threshold | Tool |
| --- | --- | --- |
| Source line limit | every Swift file ≤ 100 lines | `scripts/check_source_lines.sh` |
| Acceptance sync | generated tests match `.feature` files | `scripts/generate_acceptance_tests.py --check` |
| Dead code | none | `scripts/dead_code_check.py` |
| Duplication | none | `scripts/duplication_check.py` |
| Banned types | none | `scripts/banned_types_check.py` |
| Halstead | difficulty ≤ 20 per function | `scripts/halstead_check.py` |
| Coverage | ≥ 80% | `scripts/coverage_check.py` |
| CRAP | ≤ 30 per method | `scripts/crap_check.py` |
| Build + tests | green on iOS AND tvOS | `xcodebuild` |

Never raise a threshold or skip a gate to get green — restructure the code.

## Conventions

- **Conventional commits** (`feat:`, `fix:`, `chore:`, `refactor:`, `test:`, `docs:`,
  `ci:`). PR titles: `type(scope): what`.
- Views render; logic lives in ViewModels / Stores / Services / pure helpers (that's
  what keeps files ≤ 100 lines and coverage ≥ 80%).
- UI-affecting PRs include a simulator screenshot or recording.

## Commands

```sh
xcodegen generate              # regenerate Telly.xcodeproj from project.yml
./scripts/install-hooks.sh     # one-time: enable the pre-commit gate
./scripts/quality.sh           # full gate (what CI runs)
open Telly.xcodeproj           # develop in Xcode
```
