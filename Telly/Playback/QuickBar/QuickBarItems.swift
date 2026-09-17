import Foundation

/// One rendered quick-bar slot: its action and the label shown beneath the
/// icon. The label is the action's static `feature` name except for the four
/// stream-derived slots, which show a live value.
struct QuickBarItem: Equatable {
    let action: QuickBarAction
    let label: String
}

/// Builds the ordered nine-slot quick-bar labels from the decoded stream shape,
/// mirroring the Android `QuickBarItems`. Resolution and audio fall back to "—"
/// until the first frame's format is known; latency and subtitles come from the
/// caller. Ported 1:1 (see `QuickBarTest.kt`).
enum QuickBarItems {
    static let unknown = "—"
    private static let stereoChannels = 2

    static func items(video: VideoDetails?, sync: String = "0 ms",
                      subtitles: String = "Off") -> [QuickBarItem] {
        QuickBarAction.allCases.map { action in
            QuickBarItem(action: action, label: label(action, video, sync, subtitles))
        }
    }

    private static func label(_ action: QuickBarAction, _ video: VideoDetails?,
                              _ sync: String, _ subtitles: String) -> String {
        switch action {
        case .resolution: return resolution(video)
        case .audio: return audio(video?.audioChannels)
        case .latency: return sync
        case .subtitles: return subtitles
        default: return action.feature
        }
    }

    private static func resolution(_ video: VideoDetails?) -> String {
        guard let video, video.width > 0, video.height > 0 else { return unknown }
        return "\(video.width) × \(video.height)"
    }

    private static func audio(_ channels: Int?) -> String {
        guard let channels, channels > 0 else { return unknown }
        switch channels {
        case 1: return "Mono"
        case stereoChannels: return "Stereo"
        default: return "Surround"
        }
    }
}
