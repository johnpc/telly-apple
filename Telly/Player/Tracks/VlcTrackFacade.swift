import Foundation
import VLCKitSPM

/// Device glue conforming ``TrackFacade`` to a live `VLCMediaPlayer`: reads the
/// parallel track arrays into the pure ``VlcTrackReader`` and translates
/// selections back onto VLCKit's readwrite index/delay properties. The player is
/// weak — it is owned by ``VLCKitPlayerEngine``. Untestable ObjC bridging by
/// nature; all decision logic lives in ``VlcTrackReader`` / ``TrackPickerRows``.
final class VlcTrackFacade: TrackFacade {
    weak var player: VLCMediaPlayer?

    var snapshot: TrackSnapshot {
        guard let player else { return TrackSnapshot() }
        return VlcTrackReader.snapshot(
            audioNames: strings(player.audioTrackNames as? [NSString]),
            audioIndexes: ints(player.audioTrackIndexes as? [NSNumber]),
            currentAudio: Int(player.currentAudioTrackIndex),
            subNames: strings(player.videoSubTitlesNames as? [NSString]),
            subIndexes: ints(player.videoSubTitlesIndexes as? [NSNumber]),
            currentSub: Int(player.currentVideoSubTitleIndex))
    }

    /// VLCKit reports the delay in microseconds; the domain works in ms.
    var audioOffsetMs: Int { (player?.currentAudioPlaybackDelay ?? 0) / 1_000 }

    func selectVideo(_ id: String?) {}

    func selectAudio(_ id: String) {
        if let index = Int32(id) { player?.currentAudioTrackIndex = index }
    }

    func selectText(_ id: String?) {
        player?.currentVideoSubTitleIndex = id.flatMap(Int32.init) ?? -1
    }

    func setAudioOffsetMs(_ ms: Int) { player?.currentAudioPlaybackDelay = ms * 1_000 }

    private func ints(_ array: [NSNumber]?) -> [Int] {
        (array ?? []).map(\.intValue)
    }

    private func strings(_ array: [NSString]?) -> [String] {
        (array ?? []).map { $0 as String }
    }
}
