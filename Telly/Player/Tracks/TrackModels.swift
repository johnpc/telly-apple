import Foundation

/// One selectable video rendition; `bitrate` <= 0 when the container omits it.
struct VideoTrack: Equatable {
    let id: String
    let width: Int
    let height: Int
    let bitrate: Int
}

/// One selectable audio track; `language` is nil when undeclared.
struct AudioTrack: Equatable {
    let id: String
    let language: String?
    let channels: Int
}

/// One selectable text/CC track; `language` is nil when undeclared.
struct TextTrack: Equatable {
    let id: String
    let language: String?
}

/// What the tuned stream offers and what is picked right now, feeding the
/// quick-bar picker dialogs. `videoOverrideId` nil = adaptive "Auto";
/// `selectedTextId` nil = captions off (the engine's default). Ported from the
/// Android `TrackSnapshot`.
struct TrackSnapshot: Equatable {
    var videos: [VideoTrack] = []
    var audios: [AudioTrack] = []
    var texts: [TextTrack] = []
    var videoOverrideId: String?
    var selectedAudioId: String?
    var selectedTextId: String?
}
