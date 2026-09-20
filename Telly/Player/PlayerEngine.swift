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

    /// Total length of a finite (VOD / catch-up) stream, ms; 0 while unknown.
    var durationMs: Int { get }

    /// Tunes the given stream URL and begins playback (fresh reconnect budget).
    /// `isLive` marks an infinite stream: a live stream reporting EOF has really
    /// dropped and is retried, a finite one (VOD / catch-up archive) has finished.
    func load(_ streamUrl: String, isLive: Bool)
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

    /// Applies the video display geometry (aspect ratio / crop / stretch) for the
    /// given resize mode to the live picture. A no-op default lets non-VLC
    /// conformers and test fakes ignore it.
    func setResizeMode(_ mode: ResizeMode)
}

/// A `0` duration default so live-only conformers (and existing fakes) need not
/// implement it; the VLCKit adapter and finite-stream tests override it.
extension PlayerEngine {
    var durationMs: Int { 0 }

    /// Finite-stream convenience: VOD and catch-up archives load non-live, so
    /// their `.ended` stays terminal. Live call sites pass `isLive: true`.
    func load(_ streamUrl: String) { load(streamUrl, isLive: false) }

    func setResizeMode(_ mode: ResizeMode) {}
}
