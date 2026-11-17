<p align="center">
  <img src="assets/icon.png" alt="Telly icon" width="128" />
</p>

<h1 align="center">Telly</h1>

<p align="center"><b>An open-source, TiviMate-style IPTV player for iPhone, iPad, and Apple TV.</b></p>

<p align="center">
  <a href="../../actions/workflows/ci.yml"><img alt="CI" src="../../actions/workflows/ci.yml/badge.svg" /></a>
  <img alt="Platforms" src="https://img.shields.io/badge/platforms-iOS%2018%20%7C%20iPadOS%2018%20%7C%20tvOS%2018-lightgrey" />
  <img alt="Swift" src="https://img.shields.io/badge/Swift-5-orange.svg" />
  <a href="LICENSE"><img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-blue.svg" /></a>
  <img alt="TestFlight" src="https://img.shields.io/badge/TestFlight-beta-blue.svg" />
</p>

<p align="center">
  <img src="docs/media/guide-ipad.png" alt="Telly EPG guide on iPad" width="900" />
</p>

Telly is a native SwiftUI live-TV app for Apple platforms. Bring your own M3U
playlist and XMLTV EPG and you get a fast TV guide, instant channel zapping,
catch-up, VOD, multiview, search, favorites, watch history, and a familiar
channel-surfing feel — on iPhone, iPad, and Apple TV. There is no backend and there
are no accounts: everything is fetched on-device and cached locally. There is also
no premium tier — **every feature TiviMate paywalls ships free here**.

> Telly is an independent open-source project inspired by TiviMate's UX. It is
> **not affiliated with, endorsed by, or connected to TiviMate** or its developers
> in any way. It is a companion port of the Android
> [`telly`](https://github.com/johnpc/telly) app to Apple platforms.

## Screenshots

> All screenshots use Telly's built-in demo provider (the **Try the demo playlist**
> channels "News One / Sports Arena / Movie House / …" with their generated guide) or
> the DEBUG test-fixture playlist — no real provider is shown.

| TV guide (iPhone) | Channel list panel | Onboarding |
| --- | --- | --- |
| <img src="docs/media/guide-iphone.png" alt="TV guide on iPhone" width="260" /> | <img src="docs/media/channel-panel.png" alt="Channel list panel over live video" width="260" /> | <img src="docs/media/welcome.png" alt="Onboarding welcome screen" width="260" /> |

| Search | Settings | Catch-up |
| --- | --- | --- |
| <img src="docs/media/search.png" alt="Search across channels and programmes" width="260" /> | <img src="docs/media/settings.png" alt="Settings" width="260" /> | <img src="docs/media/catchup.png" alt="Catch-up playback of an already-aired programme" width="260" /> |

**Apple TV — full-screen EPG grid**

<p align="center">
  <img src="docs/media/guide-tvos.png" alt="Telly TV guide on Apple TV" width="800" />
</p>

**Multiview — up to four streams at once**

<p align="center">
  <img src="docs/media/multiview.png" alt="Multiview 2x2 mosaic" width="800" />
</p>

**Live playback**

<p align="center">
  <img src="docs/media/playback.png" alt="Full-screen live playback (demo stream)" width="700" />
</p>

## Features

Everything below ships free — Telly has no premium tier and no paywalls.

- **TV guide** — a timeline EPG grid with a live now-line, channel numbers,
  now/next, programme details, and day navigation.
- **Instant zapping** — channel up/down (and number entry) with a TiviMate-style zap
  overlay showing the channel number, current programme, and what's next.
- **Playback overlays & quick-bar** — info overlay (times, progress, now/next, stream
  details) plus a quick-bar for the channel list, search, multiview, track pickers
  (video / audio / subtitle-CC), and audio sync.
- **Channel-list panel** — groups + channels over the dimmed video with now-playing
  info, progress bars, and up-next, filterable by All / Live / VOD.
- **Catch-up** — channels that advertise catch-up in the playlist play already-aired
  programmes straight from the guide, with a full seek transport. Community source
  types are supported (default/template, append, shift, flussonic, xtream-codes).
- **VOD** — movie-style playlist entries become a Movies library with seekable
  playback that remembers your position and offers resume.
- **Multiview** — watch up to four streams at once in a mosaic; focus moves between
  panes and audio follows the focused pane.
- **Search** — search channels by name/number and programmes by title, with results
  spanning live and VOD.
- **Favorites & custom groups** — mark favorites and organize channels into your own
  groups.
- **My List & watch history** — save programmes to My List; recently watched channels
  are one tap away and the full history log is browsable and clearable.
- **Parental controls** — a salted-PIN lock with per-channel blocking; blocked
  channels prompt for the PIN before they tune.
- **Settings & backup** — clock format, panel timeouts, EPG refresh interval and
  past-days retention, playback options, and configuration backup/restore.
- **Simple onboarding** — first run just asks for your playlist URL (the EPG URL is
  pre-filled from the playlist's `url-tvg` hint when present).

## Platform support

- **iOS 18** (iPhone), **iPadOS 18** (iPad), **tvOS 18** (Apple TV).
- Native SwiftUI on all three; a single universal app target
  (`TARGETED_DEVICE_FAMILY = 1,2,3`).
- No backend, no account. Your playlist and EPG URLs never leave the device;
  guide/playlist data is fetched directly and cached in a local SQLite database (GRDB).

## Getting started

1. Launch Telly. On first run it asks for a playlist — tap **Add playlist** and enter
   the M3U URL from your IPTV provider.
2. If your playlist carries a `url-tvg` hint, the XMLTV EPG URL is pre-filled;
   otherwise add one under **Settings**.
3. That's it — playback starts and the TV guide is a tap/press away.

No provider yet? Tap **Try the demo playlist** instead. It installs a built-in
sample playlist (news / sports / movies / kids / music channels over Apple's public
HLS test streams, plus a small Movies shelf) with a generated, always-current TV
guide — so you can explore every screen without a server.

## Demo provider (mock backend)

Telly has no backend, but it does have a *fake provider* that lives inside the app:
`Telly/Demo/`. It is a real playlist + EPG served through the same fetch seams a
provider would go through, so the production import/refresh/guide code runs
unchanged on it. It exists for three audiences:

- **First-time users** — the welcome screen's **Try the demo playlist** button.
- **App Store review** — reviewers can exercise the whole app without access to a
  private provider's content; the review notes just say "tap Try the demo playlist".
- **CI** — the Gherkin acceptance suite runs against it, with no server, no network
  and `-tellyResetState` wiping on-device state before every scenario.

Streams are Apple's public HLS reference streams and small public sample MP4
clips; the guide (`DemoEpg`) is generated around the current clock so it never goes
stale. DEBUG builds can also install it headlessly with the `-tellyDemo` launch
argument (see `AGENTS.md` for every launch route).

## Beta (TestFlight)

Telly ships to Apple platforms via **TestFlight** (iPhone, iPad, and Apple TV).
Ask the maintainer for a TestFlight invite, or build from source below.

## Build from source

Requirements: **macOS with Xcode 26** (iOS 18 / tvOS 18 SDKs),
[`xcodegen`](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`), and
Python 3 (for the quality-gate scripts).

```sh
# 1. Generate the Xcode project from project.yml (source of truth)
xcodegen generate

# 2. Open in Xcode and run on a simulator or device
open Telly.xcodeproj

# …or build straight from the command line:
xcodebuild build -scheme Telly \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
xcodebuild build -scheme Telly \
  -destination 'platform=tvOS Simulator,name=Apple TV 4K (3rd generation)'
```

Swift Package dependencies (resolved automatically by Xcode / SPM):
- **SWCompression** — gzip/xz decompression for compressed XMLTV EPG feeds.
- **GRDB** — SQLite persistence (mirrors the Android Room layer 1:1).
- **VLCKitSPM** — libVLC behind a protocol seam (IPTV serves raw MPEG-TS, which
  AVPlayer cannot decode, so playback runs through VLCKit).

## Quality gates & testing

Telly enforces the same bar as the Android original — "fix the code, never the gate."
Run everything locally with one command:

```sh
./scripts/install-hooks.sh   # one-time: enable the pre-commit gate
./scripts/quality.sh         # run every gate (authoritative)
```

`scripts/quality.sh` runs, in order:

1. **Source line limit** — every Swift source file ≤ 100 lines (views render, logic
   lives in ViewModels/Stores/Services).
2. **Acceptance specs in sync** — generated acceptance tests match the `.feature` files.
3. **Static checks** — dead code, duplication, banned types, and Halstead difficulty ≤ 20.
4. **Unit tests + coverage (iOS)** — `xcodebuild test` with code coverage.
5. **Acceptance tests (iOS)** — the Gherkin scenarios (XCUITest) over the built-in
   demo provider — onboarding, guide, search, playback, catch-up, My List, Movies,
   settings — each from a wiped first-launch state.
6. **Acceptance tests (tvOS)** — the same scenarios driven through the Apple TV focus
   engine (Siri Remote presses), so the 10-foot UX is proven on every change.
7. **Coverage ≥ 80% + CRAP ≤ 30**.
8. **Build (iOS)**.
9. **Build (tvOS)**.

CI (`.github/workflows/ci.yml`) runs the same gates on the self-hosted Mac mini
runner; `main` requires that check, PRs auto-merge when it is green, and every green
run on `main` ships iOS + tvOS builds to TestFlight (`ios-deploy.yml`). The pre-commit hook (`scripts/pre-commit`, installed via `core.hooksPath`)
runs a fast subset (line-limit → spec sync → unit tests → build) so broken code
never lands.

### There is no such thing as a flaky test

Every test and every gate must pass on every run, locally and in CI. A test that
fails intermittently is a bug — in the test (shared state, real network, wall
clock, timing) or in the code (a race) — and is fixed at the root. Tests are never
retried, re-run, skipped or quarantined to get green, and timeouts are never
loosened to paper over nondeterminism. The seams that make this possible: injected
clocks, in-memory SQLite for every store test, a fake player engine instead of VLC,
the in-process demo provider instead of a server, and `-tellyResetState` before
every acceptance scenario. Agent-facing detail lives in `AGENTS.md`.

## Contributing

Contributions welcome. Please use **conventional commits**
(`feat:`, `fix:`, `chore:`, `refactor:`, `test:`, `docs:`, `ci:`) and make sure
`./scripts/quality.sh` is green before opening a PR — CI enforces the same gates.
UI-affecting PRs should include a screenshot or screen recording from the simulator.

## License

Released under the [MIT License](LICENSE).
