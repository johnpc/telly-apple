import Foundation

/// A VLCKit-free description of one media track, extracted by ``VlcTrackFacade``
/// from a `VLCMediaPlayer.Track` so this reader stays pure and unit-testable
/// without linking VLCKit. `id` is VLCKit 4's string `trackId`.
struct VlcTrackInfo: Equatable {
    let id: String
    let name: String
    let isSelected: Bool
}

/// Pure builder of a ``TrackSnapshot`` from the object-track lists VLCKit 4
/// exposes (`audioTracks`/`textTracks`). Track identity is now a string id (was
/// an int index in 3.x); the selected id is whichever track reports
/// `isSelected`, nil when none. No VLCKit types here so it is fully unit-tested;
/// ``VlcTrackFacade`` does the ObjC bridging and hands over plain Swift values.
enum VlcTrackReader {
    static func snapshot(audio: [VlcTrackInfo], text: [VlcTrackInfo]) -> TrackSnapshot {
        var snapshot = TrackSnapshot()
        snapshot.audios = audio.map { AudioTrack(id: $0.id, language: $0.name, channels: 0) }
        snapshot.texts = text.map { TextTrack(id: $0.id, language: $0.name) }
        snapshot.selectedAudioId = audio.first(where: \.isSelected)?.id
        snapshot.selectedTextId = text.first(where: \.isSelected)?.id
        return snapshot
    }
}
