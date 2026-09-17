import Foundation

/// The playback seam — every surface (PlaybackScreen, quick bar, catalogue)
/// drives the player through this protocol, never through VLC directly, so the
/// UI stays engine-agnostic and a fake can stand in for tests. Mirrors the
/// Android `PlayerEngine` interface. Pause/resume/seek/position and mute return
/// with the catch-up and multiview slices that use them; declaring them ahead
/// of need is deferred per the project's speculative-declaration discipline.
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
}
