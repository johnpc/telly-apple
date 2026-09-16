import Foundation

/// Info-overlay badge derivation from the decoded stream shape: a resolution
/// tier, a frame-rate badge and an audio-layout badge, each dropped when its
/// value is unknown. A 1280×720 25fps mono stream yields `["HD", "25 FPS",
/// "MONO"]`. Pure — ported from the Android `PlaybackBadges`.
enum PlaybackBadges {
    private static let uhdHeight = 2160
    private static let fhdHeight = 1080
    private static let hdHeight = 720

    static func badges(_ video: VideoDetails?) -> [String] {
        guard let video else { return [] }
        return [resolution(video.height), fps(video.frameRate), audio(video.audioChannels)]
            .compactMap { $0 }
    }

    private static func resolution(_ height: Int) -> String? {
        switch height {
        case ..<1: return nil
        case uhdHeight...: return "UHD"
        case fhdHeight...: return "FHD"
        case hdHeight...: return "HD"
        default: return "SD"
        }
    }

    private static func fps(_ frameRate: Double) -> String? {
        frameRate > 0 ? "\(Int(frameRate.rounded())) FPS" : nil
    }

    private static func audio(_ channels: Int) -> String? {
        switch channels {
        case ..<1: return nil
        case 1: return "MONO"
        case 2: return "STEREO"
        default: return "SURROUND"
        }
    }
}
