import Foundation

/// The guide grid's interactive group filter, reusing the channel list's pure
/// `ChannelListGroups` builder so a group named in the list and in the guide
/// resolve to the same channels (Favorites + All channels + playlist groups +
/// custom groups, in the same order). Kept out of the at-cap core model. The
/// selected group filters WITHIN whatever the global `PlaylistGroupFilter`
/// already allowed (that filter is applied to `channels` on `load`).
extension GuideGridModel {
    /// The chip strip's group names, with Appearance-hidden pseudo-groups dropped.
    var groups: [String] {
        visibility.filter(ChannelListGroups.groupNames(channels, customs: customGroups))
    }

    /// The channels under the selected group (every channel for "All channels",
    /// favourites for the Favorites pseudo-group, a custom group's members else).
    var selectedChannels: [ChannelEntity] {
        ChannelListGroups.channels(channels, in: selectedGroup, customs: customGroups)
    }

    /// Switches the active group filter and re-materialises the visible window
    /// live; an empty group yields zero rows (the grid renders empty, no crash).
    func selectGroup(_ group: String) {
        selectedGroup = group
        materializeRows()
    }
}
