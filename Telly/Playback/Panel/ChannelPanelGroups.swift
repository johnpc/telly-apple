import Foundation

/// Derives the channel-panel group column purely from the live channel list:
/// "All channels" first, then each playlist group in first-appearance order
/// (nil group titles dropped). Ported from the Android panel `groupNames`;
/// favourites and custom groups are deferred (no such store in telly-apple), so
/// the model reads groups straight off `model.channels`.
enum ChannelPanelGroups {
    static let allChannels = "All channels"

    /// The ordered group names: `allChannels`, the distinct non-nil playlist
    /// group titles (each at first appearance), then the custom groups last.
    static func groupNames(_ channels: [ChannelEntity], customs: [CustomGroup] = []) -> [String] {
        var seen = Set<String>()
        var names = [allChannels]
        for channel in channels {
            guard let group = channel.source.groupTitle,
                  seen.insert(group).inserted else { continue }
            names.append(group)
        }
        return names + CustomGroupChannels.names(customs)
    }

    /// The channels listed under `group`: every channel for `allChannels`, a
    /// custom group's members when `group` names one, else the playlist-group
    /// filter (first-appearance order preserved).
    static func channels(_ channels: [ChannelEntity], in group: String,
                         customs: [CustomGroup] = []) -> [ChannelEntity] {
        if group == allChannels { return channels }
        if let keys = CustomGroupChannels.members(named: group, in: customs) {
            return CustomGroupChannels.channels(channels, memberKeys: keys)
        }
        return channels.filter { $0.source.groupTitle == group }
    }
}
