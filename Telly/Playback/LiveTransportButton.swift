import Foundation

/// The three controls on the live transport row (the expanded `.infoTransport`
/// overlay): previous-channel, play/pause, next-channel. Focus moves along the
/// row with LEFT/RIGHT — clamped at the ends, since a short transport row should
/// not wrap focus back on itself — and OK (or an iPhone tap) activates the
/// focused control. Pure and unit-tested; the stateful focus lives on
/// ``LivePlaybackModel``. A live stream is never seekable (the `isLive` seam), so
/// the row carries no scrubber: channel change is its transport, and the now/next
/// bar above is the live-position indicator.
enum LiveTransportButton: Int, CaseIterable, Equatable, Sendable {
    case channelDown
    case playPause
    case channelUp

    /// Focus `delta` steps along the row, clamped to the row's ends (no wrap).
    func moved(by delta: Int) -> LiveTransportButton {
        let all = Self.allCases
        let target = min(max(rawValue + delta, 0), all.count - 1)
        return all[target]
    }

    /// The playback command this control activates when OK'd / tapped. Channel
    /// change routes through the same coalesced `.zap` the D-pad uses, so live
    /// stays non-seekable and the transport never emits an arbitrary seek.
    var command: PlaybackCommand {
        switch self {
        case .channelDown: return .zap(delta: -1)
        case .playPause: return .togglePlayPause
        case .channelUp: return .zap(delta: 1)
        }
    }
}
