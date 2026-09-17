import Foundation

/// Partitions parsed playlist entries into VOD movies vs live channels, and maps
/// the VOD side into `vod_items` rows — the Apple mirror of the Android
/// `VodImporter` (+ the `RoomPlaylistRepository` partition). Movies are
/// classified by file extension via `VodClassifier`, preserving `groupTitle` as
/// the browser category and `tvgLogo` as the card artwork.
enum VodImporter {
    /// Splits entries by `VodClassifier.isVod`, preserving each side's order.
    static func split(_ channels: [M3uChannel]) -> (vod: [M3uChannel], live: [M3uChannel]) {
        var vod: [M3uChannel] = []
        var live: [M3uChannel] = []
        for channel in channels {
            if VodClassifier.isVod(channel.streamURL) { vod.append(channel) } else { live.append(channel) }
        }
        return (vod, live)
    }

    /// Builds the `vod_items` rows for `playlistId`; `sortIndex` follows order.
    static func items(playlistId: Int, parsed: [M3uChannel]) -> [VodItem] {
        parsed.enumerated().map { index, entry in
            VodItem(id: nil, playlistId: playlistId, sortIndex: index,
                    itemKey: VodClassifier.itemKey(streamUrl: entry.streamURL, name: entry.title),
                    name: entry.title, groupTitle: entry.groupTitle,
                    logoUrl: entry.tvgLogo, streamUrl: entry.streamURL)
        }
    }
}
