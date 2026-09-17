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
    /// The active archive session, or nil while nothing plays (v1: never live —
    /// see ``mode``). `internal` setter: hop/back live in sibling extensions.
    var state: CatchupState?
    var tracker = CatchupPositionTracker()

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

    /// The VOD pause toggle: inert outside catch-up; toggles the engine when a
    /// session is active. Ports the Android `CatchupPause.toggle`.
    func togglePause() {
        guard state != nil else { return }
        if engine.paused { engine.resume() } else { engine.pause() }
    }

    /// Sample the live position from the engine (called by the screen's ticker).
    func refreshPosition() { tracker.refresh(from: engine) }

    /// The transport-row position, ms from the archive start.
    var positionMs: Int {
        #if DEBUG
        if let debugPosition { return debugPosition }
        #endif
        return tracker.position
    }

    /// The finite archive length (from the EPG window), 0 when idle.
    var durationMs: Int { state?.request.durationMs ?? 0 }

    /// Whether the transport row should show the paused pill.
    var isPaused: Bool {
        #if DEBUG
        if let debugPaused { return debugPaused }
        #endif
        return engine.paused
    }

    /// How the transport relates to what plays now: `.playing` while an archive
    /// session is active, else `.none`. This bare model holds no live channel, so
    /// Android's `.liveCapable` (rewind-into-archive-from-live) is only reachable
    /// once a live surface hosts it — a v1 deviation (plan §4).
    var mode: CatchupMode { state == nil ? .none : .playing }

    /// Tear the engine down when the screen goes away.
    func close() {
        engine.stop()
        engine.release()
    }
}
