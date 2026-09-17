import Foundation

/// VOD playback orchestrator (Apple mirror of Android's `VodPlaybackViewModel`):
/// loads the movie, offers Resume/Start-over when a stored position sits in the
/// resume band, and persists the position on pause/exit and every ~10 s. A thin
/// `@MainActor @Observable` state holder ticked by the SwiftUI screen — sampling
/// and the transport auto-hide are deadline math over the injected `now` seam.
/// Transport commands live in the `+Transport` sibling.
@MainActor
@Observable
final class VodPlaybackModel {
    let engine: any PlayerEngine
    let itemStore: VodItemStore
    let positionStore: VodPositionStore
    let itemKey: String
    let now: () -> Int
    let onExit: () -> Void

    private(set) var item: VodItem?
    private(set) var stage: VodStage = .loading
    var visibility = VodTransportVisibility()
    private var lastPersistMs = 0
    private var exited = false
    static let persistIntervalMs = 10_000

    init(engine: any PlayerEngine, itemStore: VodItemStore, positionStore: VodPositionStore,
         itemKey: String, now: @escaping () -> Int, onExit: @escaping () -> Void) {
        self.engine = engine
        self.itemStore = itemStore
        self.positionStore = positionStore
        self.itemKey = itemKey
        self.now = now
        self.onExit = onExit
    }

    /// The transport's clock sample (position + duration) from the engine.
    var progress: VodProgress { VodProgress(positionMs: engine.positionMs, durationMs: engine.durationMs) }
    /// Whether the engine is currently paused (transport pill).
    var isPaused: Bool { engine.paused }

    /// Load the movie; a vanished key just leaves the route.
    func start() {
        guard let movie = (try? itemStore.byKey(itemKey)) ?? nil else { return leave() }
        item = movie
        let stored = (try? positionStore.read(itemKey: itemKey)) ?? nil
        if let stored, VodResumePolicy.offerResume(positionMs: stored.positionMs, durationMs: stored.durationMs) {
            stage = .resumePrompt(positionMs: stored.positionMs)
        } else {
            play(fromMs: 0)
        }
    }

    /// Resume from the prompted stored position.
    func resumeStored() {
        if case let .resumePrompt(positionMs) = stage { play(fromMs: positionMs) } else { play(fromMs: 0) }
    }

    /// Start over from the beginning instead.
    func startOver() { play(fromMs: 0) }

    /// BACK: persist the position (playing only), then leave the route once.
    func exit() {
        guard stage == .playing else { return leave() }
        persist()
        leave()
    }

    /// Sampled by the screen's ticker: auto-hide the transport, finish + leave
    /// when the finite stream ends, else persist every ~10 s of playback.
    func tick() {
        visibility.resolve(at: now())
        guard stage == .playing else { return }
        if engine.state == .ended { return finish() }
        if now() - lastPersistMs >= Self.persistIntervalMs { persist(); lastPersistMs = now() }
    }

    func play(fromMs: Int) {
        guard let movie = item else { return }
        stage = .playing
        engine.load(movie.streamUrl)
        if fromMs > 0 { engine.seek(toMs: fromMs) }
        lastPersistMs = now()
        visibility.poke(paused: false, at: now())
    }

    func persist() {
        try? positionStore.save(itemKey: itemKey, positionMs: engine.positionMs, durationMs: engine.durationMs)
    }

    private func finish() {
        try? positionStore.finish(itemKey: itemKey, durationMs: engine.durationMs)
        leave()
    }

    private func leave() {
        guard !exited else { return }
        exited = true
        onExit()
    }
}
