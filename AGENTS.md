# AGENTS.md — working on Telly (Apple) as an agent

Read `CLAUDE.md` first (charter, stack, gates). This file is the operational map:
where state lives, how to drive the app headlessly, how to verify, and the rules
that are not negotiable.

## Non-negotiable rules

1. **There is no such thing as a flaky test.** Every unit, acceptance and gate
   check must pass on every run, locally and in CI. A test that fails
   intermittently is a defect — in the test (shared state, real network, wall
   clock, timing) or in the code (a race) — and is fixed at the root. Never
   retry, re-run, `@skip`, quarantine or loosen a timeout to get green.
   The seams that make this possible: injected clocks (`now: () -> Int`),
   in-memory GRDB for every store test, `FakePlayerEngine` instead of VLC,
   the in-process demo provider instead of a server, and `-tellyResetState`
   before every acceptance scenario.
2. **Fix the code, never the gate.** Thresholds in `scripts/*` are not tuned.
3. **Views render, logic lives in models.** Every file ≤ 100 lines.
4. **State is an enum, not a set of flags.** When two or more stored properties
   must agree (`isX` + `y != nil`, two optionals of which exactly one is set),
   model the states as one enum with payloads and derive the flags. The
   catalogue below is the precedent.

## State-machine catalogue

| Domain | Type | States | Driver |
| --- | --- | --- | --- |
| Data screens | `LoadPhase` | loading / loaded / empty / failed | `runLoad`, `LoadStateScaffold` |
| Player engine | `PlayerState` via `PlaybackReducer` | idle / buffering / playing / reconnecting / ended / error | VLC delegate → reducer |
| Live overlay | `PlaybackOverlay` (+ `PushedSheet`) | none / info / infoTransport / zapInfo / quickBar / panel / channelMenu / multiview / pushed(sheet, back) | `PlaybackKeyPolicy`, `OverlayVisibility` |
| Multiview layer | `MultiviewLayer` | grid / menu(selection) / picker(mode, selection) | `MultiviewSession+Menu`, `MultiviewMenuPolicy` |
| Shared live stage | `LiveStage` | idle / live(url, guideVisible) | `LiveEngineStore` |
| Guide → player | `GuidePlaybackTarget` | live(channel, url) / catchup(request) | `GuideGridScreen+Play/+Cover` |
| Wizard | `WizardStep` | typeChooser / urlEntry / xtreamEntry / processing / processed / epgUrl / done | `AddPlaylistModel` |
| VOD | `VodStage` | loading / resumePrompt(position) / playing / exited | `VodPlaybackModel` |
| Catch-up | `CatchupMode` (+ `CatchupState?`) | none / liveCapable / playing | `CatchupKeyPolicy` |
| Update feedback | `UpdatePhase` | idle / running / success(msg) / failure(msg) | `UpdateFeedbackModel` |
| DEBUG launch | `DebugLaunch.Route` | one case per screenshot/UI route + `main` | `ContentView+Debug` (exhaustive switch) |

Timed/transient state is deadline math over an injected clock (`OverlayVisibility`,
`PendingZap`, `ZapKeepFrame`, `VodTransportVisibility`), ticked by the screen —
never a sleeping coroutine.

## The demo provider (mock backend / fake server)

`Telly/Demo/` is an IPTV provider that lives inside the app and ships in release:

- `DemoContent` — the playlist (`telly://demo/playlist.m3u`): the M3U text IS the
  plan. Live channels stream Apple's public HLS reference streams ("Movie House"
  also advertises catch-up, so the guide's aired cells open the archive player);
  the "Demo Films" shelf plays one clip BUNDLED in the app (`telly://demo/clip.mp4`,
  resolved to the bundle file at play time by `DemoContent.playableUrl`) plus small
  public sample MP4s (test-videos.co.uk).
- `DemoEpg` — a deterministic XMLTV schedule generated around the current clock
  (always current, never stale), so info/guide/search/My List have content.
- The two network seams short-circuit on the demo URLs: `HttpPlaylistFetcher.fetch`
  and `EpgDownloader.download`. Everything downstream (import, refresh, synced
  config, guide) is the real production path — nothing is special-cased.

Uses: the **"Try the demo playlist"** button on the welcome screen (first-run
users, App Store review when a private provider cannot be shared), the
`-tellyDemo` launch argument (screenshots / QA), and the CI acceptance suite.

## Driving the app headlessly (DEBUG builds)

All routes resolve through `DebugLaunch.route(in:)`; precedence is pinned by
`DebugLaunchRouteTests`. Launch with `xcrun simctl launch <udid> com.johncorser.telly <args>`.

| Argument | Effect |
| --- | --- |
| any `-telly…` argument | wipes DB + defaults + synced config BEFORE launch (every proof starts from first launch); `-tellyKeepState` opts out for relaunch-persistence checks; `-tellyResetState` is the explicit spelling |
| `-tellyDemo` | install the demo provider, then show the normal app |
| `-tellySeedBase <http://host:port/>` | seed the 3-channel fixture playlist served from that base |
| `-tellyLoadState loading|empty|error` | pin the channel list's `LoadPhase` |
| `-tellyLiveDemo [-tellyOverlay <DebugLaunch.Overlay>]` | live player with ONE layer pinned: `zap info transport quickBar panel multiview multiviewMenu multiviewPicker trackAudio trackSubtitles` |
| `-tellyGuide [-tellyClock24h true|false] [-tellyChannelGroup G]` | guide grid over a seeded EPG |
| `-tellySettings`, `-tellyPlaylists`, `-tellyPlaylistDetail`, `-tellyEpgSources`, `-tellyPlaylistGroups`, `-tellyBackup`, `-tellyAppearance` | settings panes |
| `-tellyHistorySeed`, `-tellySearch`, `-tellyMyListSeed`, `-tellyVodBrowse`, `-tellyVodPlayback`, `-tellyCatchup`, `-tellyCatchupTransport`, `-tellyMultiviewDemo`, `-tellyFeedbackProof` | the remaining proofs |
| `-tellyAutoplayUrl <url>` | open the bare player on a stream |
| env `TELLY_SEED_PLAYLIST_URL` / `TELLY_SEED_EPG_URL` | import a real provider headlessly (never commit URLs) |

## Release flow

`main` is protected: the **Quality gates** check must pass before a PR can merge,
and PRs are set to auto-merge (squash) once it does. Every green CI run on `main`
then triggers `ios-deploy.yml`, which archives iOS + tvOS and uploads both to
TestFlight with a build number derived from the commit count (never collides).

## Verifying

- `./scripts/quality.sh` — the full gate (8 phases; CI runs the same steps on the
  self-hosted Mac mini). Static phases 1–3 run anywhere with Python 3.
- Acceptance scenarios are `.feature` files under `TellyUITests/Features/` (one per
  Android e2e feature area that exists on Apple: onboarding, demo, guide, search,
  playback, catch-up, My List, VOD, settings); steps live in `StepDefinitions+*.swift`
  by area, then `python3 scripts/generate_acceptance_tests.py`. Anchor steps on
  accessibility identifiers (`welcome.demo`, `player.close`, `guide.cell.<channel>|`,
  the "Previous day" guide stepper), never on time-of-day titles.
- Incremental-build trap: changing the underlying type behind a `some View`
  property (e.g. swapping a `Button<Image>` for a `Button<Label>`) does NOT recompile
  files that already inlined the old layout, and the app then segfaults in SwiftUI's
  copy helpers at runtime. On a reused `DerivedData`, `rm -rf DerivedData/Build`
  before trusting a crash; CI checks out clean so it never sees this.
- UI-affecting work is verified on the simulators with screenshots/recordings
  (`xcrun simctl io <udid> screenshot|recordVideo`) — on both iOS and tvOS.
