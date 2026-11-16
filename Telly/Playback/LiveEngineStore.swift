import Foundation

/// The app-lifetime owner of the single LIVE playback engine and of WHERE the live
/// stage is (``LiveStage``: idle, or live on one URL with the guide overlay shown
/// or hidden). One engine, one state: every live entry point acquires the same
/// engine here, the ``LivePlaybackModel`` hosted over it drives tuning and reports
/// back through `noteTuned`, and the guide overlay only flips the flag — so a
/// guide round-trip never reconnects. The engine is released only on a real `exit`.
/// VOD / catch-up keep their own per-screen engines, so their `.ended` stays terminal.
@MainActor
@Observable
final class LiveEngineStore {
    /// The live engine, non-nil between `acquire` and `exit`. `any PlayerEngine`
    /// so tests inject a fake; the surface view casts to the VLCKit concrete type.
    private(set) var engine: (any PlayerEngine)?
    private(set) var stage: LiveStage = .idle

    private let makeEngine: @MainActor () -> any PlayerEngine

    init(makeEngine: @escaping @MainActor () -> any PlayerEngine = { VLCKitPlayerEngine() }) {
        self.makeEngine = makeEngine
    }

    /// The URL currently live, or nil while idle.
    var currentUrl: String? {
        if case let .live(url, _) = stage { return url }
        return nil
    }

    /// Whether the EPG guide is layered over the live player (mini-player inset).
    var guideVisible: Bool {
        if case .live(_, true) = stage { return true }
        return false
    }

    /// The one live engine: minted on first use, reused until `exit`.
    func acquire() -> any PlayerEngine {
        if let engine { return engine }
        let minted = makeEngine()
        engine = minted
        return minted
    }

    /// The hosted model tuned `url`: the stage follows, keeping the guide flag.
    func noteTuned(_ url: String) { stage = .live(url: url, guideVisible: guideVisible) }

    /// Show / hide the guide overlay without touching the engine (it survives).
    /// Inert while idle: there is no stage to layer a guide over.
    func showGuide() { setGuide(true) }
    func hideGuide() { setGuide(false) }

    private func setGuide(_ visible: Bool) {
        guard case let .live(url, _) = stage else { return }
        stage = .live(url: url, guideVisible: visible)
    }

    /// The user has left live playback entirely: stop the stream, release the
    /// engine, and reset. The next `acquire` mints a fresh engine.
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
