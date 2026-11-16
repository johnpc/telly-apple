import Foundation

/// The app-lifetime owner of the single LIVE playback engine and the
/// guide-over-player presentation flag. Promoting the engine out of the
/// per-cover ``PlaybackScreen`` lets it survive navigation: bringing the guide
/// up as an overlay (and dismissing it) re-parents the SAME engine's drawable
/// with no reconnect, so live playback never gaps. The engine is minted lazily
/// on the first `play` and torn down only on a real `exit` from live — never
/// merely because a view covers it. VOD / catch-up keep their own per-screen
/// engines, so their `.ended` stays terminal and nothing leaks.
@MainActor
@Observable
final class LiveEngineStore {
    /// The live engine, non-nil between `play` and `exit`. `any PlayerEngine` so
    /// tests inject a fake; the surface view casts to the VLCKit concrete type.
    private(set) var engine: (any PlayerEngine)?
    /// Where the live stage is: idle, or live on one URL with the guide shown or
    /// not. One value, so "guide visible" can never outlive "something playing".
    private(set) var stage: LiveStage = .idle

    /// The stream currently loaded. A repeat `play` of the same URL is a no-op,
    /// so re-entering a channel never re-opens (and re-buffers) the stream.
    var currentUrl: String? {
        if case let .live(url, _) = stage { return url }
        return nil
    }
    /// Whether the EPG guide is layered over the live player (mini-player inset).
    var guideVisible: Bool {
        if case .live(_, true) = stage { return true }
        return false
    }

    private let makeEngine: @MainActor () -> any PlayerEngine

    init(makeEngine: @escaping @MainActor () -> any PlayerEngine = { VLCKitPlayerEngine() }) {
        self.makeEngine = makeEngine
    }

    /// Resolve the shared engine and tune `url` on it. Reuses the live engine
    /// across navigation; only actually loads when the URL changed, so a guide
    /// round-trip (or a re-tap of the current channel) causes no reconnect.
    func play(_ url: String) {
        let resolved = engine ?? makeEngine()
        engine = resolved
        guard url != currentUrl else { return }
        stage = .live(url: url, guideVisible: guideVisible)
        resolved.load(url, isLive: true)
    }

    /// Show / hide the guide overlay without touching the engine (it survives).
    /// Inert while idle: there is no stage to layer a guide over.
    func showGuide() { setGuide(true) }
    func hideGuide() { setGuide(false) }

    private func setGuide(_ visible: Bool) {
        guard case let .live(url, _) = stage else { return }
        stage = .live(url: url, guideVisible: visible)
    }

    /// The user has left live playback entirely: stop the stream, release the
    /// engine, and reset. The next `play` mints a fresh engine.
    func exit() {
        engine?.stop()
        engine?.release()
        engine = nil
        stage = .idle
    }
}

/// The shared live stage's lifecycle: nothing playing, or one live URL with the
/// guide overlay shown or hidden.
enum LiveStage: Equatable {
    case idle
    case live(url: String, guideVisible: Bool)
}
