import Foundation

/// Playback status exposed to the UI, mirrored from the Android `PlayerState`
/// sealed interface so both platforms share one mental model.
enum PlayerState: Equatable {
    case idle
    case buffering
    case playing
    /// A live stream dropped and the engine is re-preparing it (auto-reconnect
    /// with backoff). Transient — resolves to `.playing` or `.error`.
    case reconnecting
    /// A finite stream (archive / VOD) reached its end.
    case ended
    case error(String)
}

/// Stream characteristics feeding the info-overlay badges (HD / FPS / channels).
struct VideoDetails: Equatable {
    let width: Int
    let height: Int
    let frameRate: Double
    let audioChannels: Int
}

/// Seam between playback logic and the concrete engine (VLCKit for raw
/// MPEG-TS + HLS + MP4; see telly-apple decisions log). View models talk to
/// this protocol only, so tests inject a fake and never touch VLCKit/AVKit.
///
/// IPTV serves raw MPEG-TS, which AVPlayer cannot decode — hence VLCKit as the
/// baseline engine. This protocol keeps that choice swappable.
protocol PlayerEngine: AnyObject {
    var state: PlayerState { get }
    var video: VideoDetails? { get }
    /// True while playback is user-paused; `load` and `stop` reset it.
    var paused: Bool { get }

    func load(streamURL: URL)
    func stop()
    func setMuted(_ muted: Bool)
    func pause()
    func resume()
    /// Current playback position in seconds (catch-up transport readout).
    func positionSeconds() -> Double
    /// Absolute seek within a finite (catch-up / VOD) stream.
    func seek(toSeconds seconds: Double)
}
