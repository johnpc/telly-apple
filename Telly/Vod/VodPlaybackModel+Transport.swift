import Foundation

/// VOD transport commands (Apple mirror of Android's `VodPlayerControls` + seek
/// steps): the pause toggle persists on a fresh pause, relative seek clamps to
/// the known duration, and every command re-pokes the auto-hide transport. Split
/// from the base model to keep it within the source-line budget. The Slice-5 key
/// mapper dispatches LEFT/RIGHT to ``seekStepMs`` and RW/FF to ``jumpStepMs``.
extension VodPlaybackModel {
    /// LEFT/RIGHT seek step.
    static var seekStepMs: Int { 10_000 }
    /// RW/FF jump step.
    static var jumpStepMs: Int { 30_000 }

    /// OK: toggle pause; a fresh pause persists the position immediately.
    func togglePause() {
        guard stage == .playing else { return }
        if engine.paused {
            engine.resume()
        } else {
            engine.pause()
            persist()
        }
        visibility.poke(paused: engine.paused, at: now())
    }

    /// Relative seek within the movie, clamped to [0, duration] and re-poking
    /// the transport so the row stays up through a burst of seeks.
    func seekBy(_ deltaMs: Int) {
        guard stage == .playing else { return }
        let duration = engine.durationMs
        let target = max(0, engine.positionMs + deltaMs)
        engine.seek(toMs: duration > 0 ? min(target, duration) : target)
        visibility.poke(paused: engine.paused, at: now())
    }

    /// UP/DOWN: reveal the transport without changing playback.
    func pokeTransport() { visibility.poke(paused: engine.paused, at: now()) }
}
