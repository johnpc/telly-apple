import Foundation

/// Hides channels whose playlist group the user has disabled — the Apple mirror
/// of the Android `PlaylistGroupFilter`. A channel is kept when it has no group
/// at all, when its playlist is unknown (so no group-enabled flag can be
/// resolved), or when `groupEnabled(url, group)` is true. Pure: the visible
/// snapshot is filtered in memory, so `ChannelStore.visibleChannels()` SQL is
/// untouched.
enum PlaylistGroupFilter {
    static func visible(_ channels: [ChannelEntity],
                        playlistUrlById: [Int: String],
                        groupEnabled: (String, String) -> Bool) -> [ChannelEntity] {
        channels.filter { channel in
            guard let group = channel.source.groupTitle else { return true }
            guard let url = playlistUrlById[channel.playlistId] else { return true }
            return groupEnabled(url, group)
        }
    }
}
