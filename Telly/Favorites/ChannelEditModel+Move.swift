import Foundation

extension ChannelEditModel {
    /// Moves `channel` by `delta` positions, persisting only the changed rows.
    /// Manage-Favorites (and the Favorites pseudo-group) reindex `favoriteOrder`;
    /// any other group swaps neighbours' `sortIndex`.
    func move(_ channel: ChannelEntity, delta: Int) {
        let updates = favoritesMode
            ? ChannelReorder.moveFavorite(channels, channelId: channel.id, delta: delta)
            : ChannelReorder.moveInGroup(rows, channelId: channel.id, delta: delta)
        guard !updates.isEmpty else { return }
        try? store.update(updates)
        load()
    }

    /// Reorder targets favourite order in Manage-Favorites mode or under the
    /// Favorites pseudo-group; every real group reorders by `sortIndex`.
    private var favoritesMode: Bool {
        group == nil || group == ChannelListGroups.favorites
    }
}
