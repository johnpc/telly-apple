import Foundation

/// The live-playback orchestrator: ONE ``LiveSession`` value (single-stream overlay
/// machine, or multiview) plus the pure timed cores (``PendingZap`` /
/// ``ZapKeepFrame`` / ``ChannelZapper`` / ``PlaybackKeyPolicy``) over a real
/// ``PlayerEngine`` and a channel snapshot.
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
    /// WHERE the stage is — single-stream playback with its overlay machine, or
    /// the N-up multiview session — as one value (see ``LiveSession``). `internal`
    /// setter: the `+Session` helpers in this module drive its transitions.
    var session: LiveSession = .single(OverlayVisibility())
    let channels: [ChannelEntity]
    /// Tuned channel; `internal` setter for the `+Tune` sibling.
    var current: ChannelEntity?
    /// The current video resize / aspect-ratio mode, applied on start / tune.
    /// (Which picker card is up lives in ``overlay`` as ``PushedSheet`` — not here.)
    var resizeMode: ResizeMode
    let persistResizeMode: (ResizeMode) -> Void
    /// Set by the search quick-bar slot; the screen presents the search cover.
    var searchRequested = false
    /// Builds the search screen's model for that cover (nil in unit tests).
    let makeSearchModel: (@MainActor () -> SearchModel)?

    /// Which live-transport control the expanded `.infoTransport` row has focused.
    var transportFocus: LiveTransportButton = .playPause
    var pendingZap = PendingZap()
    var keepFrame = ZapKeepFrame()
    let keymap: PlayerKeymap
    let timeouts: PanelTimeouts

    let now: () -> Int
    let persistLastChannel: (Int) -> Void
    let loadLastChannel: () -> Int?
    /// The channel the stage was opened ON (a tapped row); nil restores the last-watched.
    let initialChannelId: Int?
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
         initialChannelId: Int? = nil,
         onExitToGuide: @escaping () -> Void,
         nowNext: @escaping (ChannelEntity) -> NowNext? = { _ in nil },
         resizeMode: ResizeMode = .fit,
         persistResizeMode: @escaping (ResizeMode) -> Void = { _ in },
         makeSearchModel: (@MainActor () -> SearchModel)? = nil) {
        self.engine = engine
        self.resizeMode = resizeMode
        self.persistResizeMode = persistResizeMode
        self.makeSearchModel = makeSearchModel
        self.channels = channels
        self.makeEngine = makeEngine
        self.keymap = keymap
        self.timeouts = timeouts
        self.now = now
        self.persistLastChannel = persistLastChannel
        self.loadLastChannel = loadLastChannel
        self.initialChannelId = initialChannelId
        self.onExitToGuide = onExitToGuide
        self.nowNext = nowNext
    }

    /// Cold start: tune the channel the stage was opened on, else restore the
    /// last-watched (else the first) — silently: no zap overlay, no keep-frame grace.
    func start() {
        current = ChannelZapper.restore(channels, lastChannelId: initialChannelId ?? loadLastChannel())
        guard let channel = current else { return }
        engine.load(channel.source.streamUrl, isLive: true)
        engine.setResizeMode(resizeMode)
        persistLastChannel(channel.id)
    }
}
