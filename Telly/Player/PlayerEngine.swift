import Foundation

/// The playback seam — every surface (PlaybackScreen, quick bar, catalogue)
/// drives the player through this protocol, never through VLC directly, so the
/// UI stays engine-agnostic and a fake can stand in for tests. Mirrors the
/// Android `PlayerEngine` interface. Class-bound because both the real
/// `VLCKitPlayerEngine` and any observable fake are reference types.
@MainActor
protocol PlayerEngine: AnyObject {
    var state: PlayerState { get }
    var video: VideoDetails? { get }
    var paused: Bool { get }
    var tracks: TrackFacade { get }

    /// Tunes the given stream URL and begins playback (fresh reconnect budget).
    func load(_ streamUrl: String)
    func stop()
    func release()
    func setMuted(_ muted: Bool)
    func pause()
    func resume()
    func positionMs() -> Int
    func seekTo(_ positionMs: Int)
}
