import Foundation
import VLCKit

/// Device glue conforming ``TrackFacade`` to a live `VLCMediaPlayer`: reads the
/// VLCKit 4 object-track lists (`audioTracks`/`textTracks`) into plain
/// ``VlcTrackInfo`` values for the pure ``VlcTrackReader`` and translates
/// selections back via each track's `isSelectedExclusively`. Track identity is a
/// string `trackId` (was an int index in 3.x). The player is weak — it is owned
/// by ``VLCKitPlayerEngine``. Untestable ObjC bridging by nature; all decision
/// logic lives in ``VlcTrackReader`` / ``TrackPickerRows``.
final class VlcTrackFacade: TrackFacade {
    weak var player: VLCMediaPlayer?

    var snapshot: TrackSnapshot {
        guard let player else { return TrackSnapshot() }
        return VlcTrackReader.snapshot(audio: infos(player.audioTracks),
                                       text: infos(player.textTracks))
    }

    /// VLCKit reports the delay in microseconds; the domain works in ms.
    var audioOffsetMs: Int { (player?.currentAudioPlaybackDelay ?? 0) / 1_000 }

    func selectVideo(_ id: String?) {}

    func selectAudio(_ id: String) {
        track(id, in: player?.audioTracks)?.isSelectedExclusively = true
    }

    func selectText(_ id: String?) {
        guard let id, let track = track(id, in: player?.textTracks) else {
            player?.deselectAllTextTracks(); return
        }
        track.isSelectedExclusively = true
    }

    func setAudioOffsetMs(_ ms: Int) { player?.currentAudioPlaybackDelay = ms * 1_000 }

    private func track(_ id: String, in tracks: [VLCMediaPlayer.Track]?) -> VLCMediaPlayer.Track? {
        (tracks ?? []).first { $0.trackId == id }
    }

    private func infos(_ tracks: [VLCMediaPlayer.Track]) -> [VlcTrackInfo] {
        tracks.map { VlcTrackInfo(id: $0.trackId, name: $0.trackName, isSelected: $0.isSelected) }
    }
}
