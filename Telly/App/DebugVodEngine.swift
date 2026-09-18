#if DEBUG
import Foundation

/// A DEBUG-only ``PlayerEngine`` stub for the VOD playback screenshot proofs.
/// Simulators can't reliably decode VOD, so this decodes nothing and instead
/// reports a canned position/duration, letting the transport's clocks and
/// progress bar render over the black stage without live playback. Every command
/// is inert; the cast to ``VLCKitPlayerEngine`` in the screen fails, so no video
/// surface is attached. Never compiled into release.
@MainActor
final class DebugVodEngine: PlayerEngine {
    var state: PlayerState = .playing
    var video: VideoDetails?
    var paused = false
    var positionMs: Int
    var durationMs: Int
    var tracks: TrackFacade = NoTracks()

    init(positionMs: Int, durationMs: Int) {
        self.positionMs = positionMs
        self.durationMs = durationMs
    }

    func load(_ streamUrl: String, isLive: Bool) {}
    func stop() {}
    func release() {}
    func pause() { paused = true }
    func resume() { paused = false }
    func seek(toMs positionMs: Int) { self.positionMs = positionMs }
    func setMuted(_ muted: Bool) {}
}
#endif
