import Foundation

/// The four quick-bar stream slots that open a picker dialog over playback:
/// video track, audio track, audio-sync offset, closed captions. The Android
/// `QuickBarAction` coupling is dropped here — it belongs to the later
/// quick-bar UI slice. Ported from the Android `TrackPickerKind`.
enum TrackPickerKind: CaseIterable {
    case video
    case audio
    case sync
    case subtitles

    var title: String {
        switch self {
        case .video: return "Video track"
        case .audio: return "Audio track"
        case .sync: return "Audio sync"
        case .subtitles: return "Closed captions"
        }
    }
}
