import Foundation

/// Appearance→Groups toggles for the two pseudo-groups (mirrors the Android
/// `features/panel/GroupVisibility.kt`): when off, that pseudo-group is dropped
/// from the channel-list group picker. Real playlist groups are never hidden.
struct GroupVisibility: Equatable {
    var allChannels = true
    var favorites = true

    /// Both pseudo-groups shown — the default channel-list state.
    static let standard = GroupVisibility()

    /// Drops the `Favorites` / `All channels` pseudo-groups toggled off.
    func filter(_ groups: [String]) -> [String] {
        groups.filter { name in
            if name == ChannelListGroups.favorites { return favorites }
            if name == ChannelPanelGroups.allChannels { return allChannels }
            return true
        }
    }
}
