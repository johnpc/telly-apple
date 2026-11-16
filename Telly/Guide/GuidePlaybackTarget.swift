import Foundation

/// What the guide is about to play, driving its fullscreen cover: a channel's
/// LIVE stream, or one resolved catch-up ARCHIVE request. Two cases instead of a
/// url + two optionals — so "live" and "catch-up" cannot be half-set, and the
/// cover switches exhaustively (``GuideGridScreen/playbackCover(_:)``).
enum GuidePlaybackTarget: Identifiable, Equatable {
    /// Tune this channel's live stream through the chrome-less ``PlaybackScreen``.
    case live(channelId: Int, url: String)
    /// Play an archived programme through the transport-driven ``CatchupPlaybackScreen``.
    case catchup(CatchupRequest)

    /// The channel being played — the `.fullScreenCover(item:)` identity.
    var id: Int {
        switch self {
        case let .live(channelId, _): return channelId
        case let .catchup(request): return request.channel.id
        }
    }

    /// The stream URL the cover opens, whichever case is active.
    var url: String {
        switch self {
        case let .live(_, url): return url
        case let .catchup(request): return request.url
        }
    }
}

extension CatchupBadge {
    /// The archive chrome for a resolved request: its title + wall-clock window.
    init(_ request: CatchupRequest) {
        self.init(title: request.title, startMs: request.startMs, endMs: request.endMs)
    }
}
