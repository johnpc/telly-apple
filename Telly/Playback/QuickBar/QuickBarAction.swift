import Foundation

/// The nine fullscreen quick-bar slots, ported 1:1 (order + labels) from the
/// Android `QuickBarAction`. `feature` is the static slot label; the four
/// stream-derived slots (resolution/audio/latency/subtitles) override it with a
/// live value in ``QuickBarItems``.
enum QuickBarAction: CaseIterable, Equatable, Sendable {
    case search
    case channelsList
    case recordings
    case multiview
    case pictureInPicture
    case resolution
    case audio
    case latency
    case subtitles

    var feature: String {
        switch self {
        case .search: return "Search"
        case .channelsList: return "Channels list"
        case .recordings: return "Recordings"
        case .multiview: return "Multiview"
        case .pictureInPicture: return "Picture-in-picture"
        case .resolution: return "Video track"
        case .audio: return "Audio track"
        case .latency: return "Latency"
        case .subtitles: return "Subtitles"
        }
    }
}
