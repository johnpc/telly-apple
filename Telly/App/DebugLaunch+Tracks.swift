#if DEBUG
import Foundation

extension DebugLaunch {
    /// The track picker to force open for the screenshot proof, or nil:
    /// `-tellyOverlay trackAudio` → `.audio`, `trackSubtitles` → `.subtitles`.
    static func forcedTrackPicker(in args: [String]) -> TrackPickerKind? {
        switch value(for: "-tellyOverlay", in: args) {
        case "trackAudio": return .audio
        case "trackSubtitles": return .subtitles
        default: return nil
        }
    }

    /// A canned two-audio / one-subtitle snapshot so the picker renders real rows
    /// without a decoded live stream: English + Spanish audio (English selected),
    /// one English caption track, captions off.
    static func trackFixtureSnapshot() -> TrackSnapshot {
        var snapshot = TrackSnapshot()
        snapshot.audios = [AudioTrack(id: "0", language: "en", channels: 2),
                           AudioTrack(id: "1", language: "es", channels: 2)]
        snapshot.texts = [TextTrack(id: "0", language: "en")]
        snapshot.selectedAudioId = "0"
        return snapshot
    }
}
#endif
