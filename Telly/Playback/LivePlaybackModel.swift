import Foundation

/// The live-playback orchestrator: composes the pure S1–S3 value types
/// (``OverlayVisibility`` / ``PendingZap`` / ``ZapKeepFrame`` / ``ChannelZapper``
/// / ``PlaybackKeyPolicy``) over a real ``PlayerEngine`` and a channel snapshot.
/// A thin `@MainActor @Observable` state holder ticked by the SwiftUI screen's
/// timer — NOT a coroutine host. All decision logic lives here (unit-tested);
/// the screen only renders `overlay`/`current`/`holdsLastFrame` and forwards
/// keys through ``onKey(_:)``. The `now`/`persist`/`load`/`exit` seams are the
/// Apple mirror of Android's injected clock and repository dependencies.
@MainActor
@Observable
final class LivePlaybackModel {
    let engine: any PlayerEngine
    /// Mints a fresh engine per multiview tile; defaulted to the real VLCKit one.
    let makeEngine: @MainActor () -> any PlayerEngine
    /// The live multiview session while the `.multiview` overlay is up, else nil.
    var multiview: MultiviewSession?
    let channels: [ChannelEntity]
    // `internal` setter (not `private(set)`): `tune`/`start` live in sibling
    // extension files in this module and must assign it.
    var current: ChannelEntity?
    /// The track picker `.pushed` over the quick-bar shows, nil when none is up.
    var activePicker: TrackPickerKind?

    var visibility = OverlayVisibility()
    var pendingZap = PendingZap()
    var keepFrame = ZapKeepFrame()
    let keymap: PlayerKeymap
    let timeouts: PanelTimeouts

    let now: () -> Int
    let persistLastChannel: (Int) -> Void
    let loadLastChannel: () -> Int?
    let onExitToGuide: () -> Void
    /// Now/next feed for the info overlay, keyed off the tuned channel. Defaults
    /// to no data so existing call sites/tests compile; wired to `GuideEpgStore`
    /// in `AppEnvironment`.
    let nowNext: (ChannelEntity) -> NowNext?

    #if DEBUG
    /// Screenshot-only override so the tvOS overlay proof holds the black stage
    /// (no buffering spinner) while the pinned zap overlay is captured.
    var debugHoldFrame = false
    /// Screenshot-only canned track snapshot feeding the picker without a decoded
    /// live stream (the live engine has no tracks under a fixture playlist).
    var debugSnapshot: TrackSnapshot?
    #endif

    init(engine: any PlayerEngine,
         channels: [ChannelEntity],
         makeEngine: @escaping @MainActor () -> any PlayerEngine = { VLCKitPlayerEngine() },
         keymap: PlayerKeymap = PlayerKeymap(),
         timeouts: PanelTimeouts = .default,
         now: @escaping () -> Int,
         persistLastChannel: @escaping (Int) -> Void,
         loadLastChannel: @escaping () -> Int?,
         onExitToGuide: @escaping () -> Void,
         nowNext: @escaping (ChannelEntity) -> NowNext? = { _ in nil }) {
        self.engine = engine
        self.channels = channels
        self.makeEngine = makeEngine
        self.keymap = keymap
        self.timeouts = timeouts
        self.now = now
        self.persistLastChannel = persistLastChannel
        self.loadLastChannel = loadLastChannel
        self.onExitToGuide = onExitToGuide
        self.nowNext = nowNext
    }

    /// The now/next for the currently tuned channel, or nil when none.
    var currentInfo: NowNext? { current.flatMap(nowNext) }

    /// The overlay layer the screen should render this frame.
    var overlay: PlaybackOverlay { visibility.overlay }

    /// Whether to hold the last video frame instead of a buffering spinner now.
    var holdsLastFrame: Bool {
        #if DEBUG
        if debugHoldFrame { return true }
        #endif
        return keepFrame.holdsLastFrame(state: engine.state, at: now())
    }

    /// Cold start: restore the last-watched channel (else the first) and tune it
    /// silently — no zap overlay, no keep-frame grace (this is not a zap).
    func start() {
        current = ChannelZapper.restore(channels, lastChannelId: loadLastChannel())
        guard let channel = current else { return }
        engine.load(channel.source.streamUrl)
        persistLastChannel(channel.id)
    }

    /// Tear the engine down when the screen goes away.
    func close() {
        engine.stop()
        engine.release()
    }
}
