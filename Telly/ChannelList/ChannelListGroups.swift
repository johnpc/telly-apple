import Foundation

/// The channel-list group picker's model: the playback panel's group names
/// (read-only) with the `Favorites` pseudo-group prepended, and favourite
/// filtering delegated to `ChannelReorder`. Kept OUT of the playback `Panel`
/// slice so the channel-list domain stays independent — it *composes* the
/// existing `ChannelPanelGroups` rather than editing it. Mirrors the Android
/// `features/panel/PanelRows` `groupNames`/`channelsIn`.
enum ChannelListGroups {
    static let favorites = "Favorites"

    /// `[Favorites, All channels] + playlist groups + custom groups`, matching
    /// the Android panel (custom groups appended last).
    static func groupNames(_ channels: [ChannelEntity], customs: [CustomGroup] = []) -> [String] {
        [favorites] + ChannelPanelGroups.groupNames(channels) + CustomGroupChannels.names(customs)
    }

    /// The channels under `group`: favourites (in managed order) for the
    /// `Favorites` pseudo-group, a custom group's members when `group` names one,
    /// otherwise the playback panel's playlist-group filter.
    static func channels(_ channels: [ChannelEntity], in group: String,
                         customs: [CustomGroup] = []) -> [ChannelEntity] {
        if group == favorites { return ChannelReorder.favorites(channels) }
        if let keys = CustomGroupChannels.members(named: group, in: customs) {
            return CustomGroupChannels.channels(channels, memberKeys: keys)
        }
        return ChannelPanelGroups.channels(channels, in: group)
    }
}
