import Foundation

/// The channel-list group picker's model: the playback panel's group names
/// (read-only) with the `Favorites` pseudo-group prepended, and favourite
/// filtering delegated to `ChannelReorder`. Kept OUT of the playback `Panel`
/// slice so the channel-list domain stays independent — it *composes* the
/// existing `ChannelPanelGroups` rather than editing it. Mirrors the Android
/// `features/panel/PanelRows` `groupNames`/`channelsIn`.
enum ChannelListGroups {
    static let favorites = "Favorites"

    /// `[Favorites, All channels] + playlist groups`, matching the Android panel.
    static func groupNames(_ channels: [ChannelEntity]) -> [String] {
        [favorites] + ChannelPanelGroups.groupNames(channels)
    }

    /// The channels under `group`: favourites (in managed order) for the
    /// `Favorites` pseudo-group, otherwise the playback panel's group filter.
    static func channels(_ channels: [ChannelEntity], in group: String) -> [ChannelEntity] {
        group == favorites ? ChannelReorder.favorites(channels)
                           : ChannelPanelGroups.channels(channels, in: group)
    }
}
