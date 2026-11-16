import Foundation

/// The catch-up transport orchestrator: composes the pure S1–S3 cores
/// (``CatchupPositionTracker`` / ``SeekMath`` / ``CatchupKeyPolicy`` /
/// ``CatchupNeighbours`` / ``CatchupLiveEdge``) over a real ``PlayerEngine`` for
/// finite (archived) playback. A thin `@MainActor @Observable` state holder
/// ticked by the SwiftUI screen — NOT a coroutine host; the screen samples the
/// position and forwards keys, all decision logic lives here (unit-tested).
/// Mirrors the live model's shape while keeping ``LivePlaybackModel`` untouched.
/// The `now`/`onExitToGuide` seams mirror Android's injected clock + host.
@MainActor
@Observable
final class CatchupPlaybackModel {
    let engine: any PlayerEngine
    /// Where the transport is (idle / live / archive). `internal` setter: the
    /// hop/back transitions live in sibling extensions.
    var stage: CatchupStage = .idle
    var tracker = CatchupPositionTracker()

    /// The active archive session, or nil outside archive playback.
    var state: CatchupState? {
        if case let .archive(state) = stage { return state }
        return nil
    }

    let neighbours: CatchupNeighbours
    let liveEdge: CatchupLiveEdge
    let keys: CatchupSeekKeys
    let skip: CatchupSkip
    let now: () -> Int
    /// Where BACK escapes when leaving the archive (not rewound-from-live): the
    /// production `CatchupPlaybackScreen` overrides this to `dismiss()` the cover,
    /// so it is `var` (init-injected default stays the factory's `{}`).
    var onExitToGuide: () -> Void

    #if DEBUG
    /// Screenshot-only overrides so the transport row proof holds a scrubbed
    /// position / paused pill without a decoded finite stream (Slice 6).
    var debugPosition: Int?
    var debugPaused: Bool?
    #endif

    init(engine: any PlayerEngine,
         neighbours: CatchupNeighbours,
         liveEdge: CatchupLiveEdge,
         keys: CatchupSeekKeys = .appleDefaults,
         skip: CatchupSkip = .defaults,
         now: @escaping () -> Int,
         onExitToGuide: @escaping () -> Void) {
        self.engine = engine
        self.neighbours = neighbours
        self.liveEdge = liveEdge
        self.keys = keys
        self.skip = skip
        self.now = now
        self.onExitToGuide = onExitToGuide
    }

    /// Begin transport on the initial archive request (guide/history hand-off).
    func start(_ request: CatchupRequest) { enter(request, fromLive: false) }

    /// The VOD pause toggle: inert while idle; toggles the engine when live or
    /// an archive session is active. Ports the Android `CatchupPause.toggle`.
    func togglePause() {
        guard stage != .idle else { return }
        if engine.paused { engine.resume() } else { engine.pause() }
    }

    /// Sample the live position from the engine (called by the screen's ticker).
    func refreshPosition() { tracker.refresh(from: engine) }

    /// The screen's heartbeat: sample the position, then return to live if the
    /// finite archive has ended.
    func tick() {
        refreshPosition()
        handleEndedIfNeeded()
    }

    /// How the transport relates to what plays now — derived from ``stage``, so
    /// after returning to live the channel keeps its rewind-into-archive keys.
    var mode: CatchupMode { stage.mode }

    /// Tear the engine down when the screen goes away.
    func close() {
        engine.stop()
        engine.release()
    }
}
