import Foundation

extension ChannelListModel {
    /// Toggles a channel's favourite flag, persists it, then reloads so the
    /// star indicator and the Favorites filter reflect the change.
    func toggleFavorite(_ channel: ChannelEntity) {
        try? store.update(ChannelReorder.toggled(channels, channel))
        load()
    }

    /// Hides a channel from the visible list, persists it, then reloads.
    func hide(_ channel: ChannelEntity) {
        var updated = channel
        updated.flags.hidden = true
        try? store.update(updated)
        load()
    }
}
