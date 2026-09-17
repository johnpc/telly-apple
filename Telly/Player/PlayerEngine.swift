import Foundation

/// The playback seam — every surface (PlaybackScreen, quick bar, catalogue)
/// drives the player through this protocol, never through VLC directly, so the
/// UI stays engine-agnostic and a fake can stand in for tests. Mirrors the
/// Android `PlayerEngine` interface. Pause/resume/seek/position return with the
/// catch-up slice that uses them; declaring them ahead of need is deferred per
/// the project's speculative-declaration discipline. `setMuted` arrives with
/// multiview, which keeps exactly one tile audible.
@MainActor
protocol PlayerEngine {
    var state: PlayerState { get }
    var video: VideoDetails? { get }
    var paused: Bool { get }
    var tracks: TrackFacade { get }

    /// Tunes the given stream URL and begins playback (fresh reconnect budget).
    func load(_ streamUrl: String)
    func stop()
    func release()

    /// Mutes or unmutes this engine's audio; multiview mutes all but the active.
    func setMuted(_ muted: Bool)
}
