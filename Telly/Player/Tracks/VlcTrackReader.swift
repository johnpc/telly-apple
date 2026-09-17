import Foundation

/// Pure builder of a ``TrackSnapshot`` from VLCKit's parallel name/index arrays.
/// Zips names↔indexes to the shorter length, drops the negative "Disable"
/// sentinel VLCKit prepends, and derives the selected id from the current index
/// (nil when -1 / disabled). No VLCKit types here so it is fully unit-tested;
/// ``VlcTrackFacade`` does the ObjC bridging and hands over plain Swift arrays.
enum VlcTrackReader {
    static func snapshot(audioNames: [String], audioIndexes: [Int], currentAudio: Int,
                         subNames: [String], subIndexes: [Int], currentSub: Int) -> TrackSnapshot {
        var snapshot = TrackSnapshot()
        snapshot.audios = zipped(audioNames, audioIndexes).map { name, index in
            AudioTrack(id: String(index), language: name, channels: 0)
        }
        snapshot.texts = zipped(subNames, subIndexes).map { name, index in
            TextTrack(id: String(index), language: name)
        }
        snapshot.selectedAudioId = selected(currentAudio)
        snapshot.selectedTextId = selected(currentSub)
        return snapshot
    }

    /// Pairs parallel arrays (truncating to the shorter) and drops the negative
    /// "Disable" sentinel VLCKit lists at index 0 of each track kind.
    private static func zipped(_ names: [String], _ indexes: [Int]) -> [(String, Int)] {
        zip(names, indexes).filter { $0.1 >= 0 }
    }

    /// The selected track id for a VLCKit "current index": nil when disabled (-1).
    private static func selected(_ index: Int) -> String? {
        index >= 0 ? String(index) : nil
    }
}
