import Foundation

/// The playback seam — every surface (PlaybackScreen, quick bar, catalogue)
/// drives the player through this protocol, never through VLC directly, so the
/// UI stays engine-agnostic and a fake can stand in for tests. Mirrors the
/// Android `PlayerEngine` interface. Pause/resume/seek/position drive catch-up
/// transport over a finite (archived) stream; `setMuted` arrives with
/// multiview, which keeps exactly one tile audible.
@MainActor
protocol PlayerEngine {
    var state: PlayerState { get }
    var video: VideoDetails? { get }
    var paused: Bool { get }
    var tracks: TrackFacade { get }

    /// Current playback position, ms, within a finite (catch-up) stream.
    var positionMs: Int { get }

    /// Tunes the given stream URL and begins playback (fresh reconnect budget).
    func load(_ streamUrl: String)
    func stop()
    func release()

    /// User pause (catch-up transport ⏸); a no-op while already paused.
    func pause()
    /// Resumes a paused stream.
    func resume()
    /// Absolute seek within a finite (catch-up) stream.
    func seek(toMs positionMs: Int)

    /// Mutes or unmutes this engine's audio; multiview mutes all but the active.
    func setMuted(_ muted: Bool)
}
