import Foundation

/// Derives the channel-panel group column purely from the live channel list:
/// "All channels" first, then each playlist group in first-appearance order
/// (nil group titles dropped). Ported from the Android panel `groupNames`;
/// favourites and custom groups are deferred (no such store in telly-apple), so
/// the model reads groups straight off `model.channels`.
enum ChannelPanelGroups {
    static let allChannels = "All channels"

    /// The ordered group names: `allChannels` then the distinct non-nil group
    /// titles, each kept at its first appearance.
    static func groupNames(_ channels: [ChannelEntity]) -> [String] {
        var seen = Set<String>()
        var names = [allChannels]
        for channel in channels {
            guard let group = channel.source.groupTitle,
                  seen.insert(group).inserted else { continue }
            names.append(group)
        }
        return names
    }

    /// The channels listed under `group`: every channel for `allChannels`, else
    /// the group filter (first-appearance order preserved).
    static func channels(_ channels: [ChannelEntity], in group: String) -> [ChannelEntity] {
        group == allChannels ? channels : channels.filter { $0.source.groupTitle == group }
    }
}
