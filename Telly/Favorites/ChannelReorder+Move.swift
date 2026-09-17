import Foundation

extension ChannelReorder {
    /// Moves a favourite up/down within the favourites order by `delta`,
    /// reindexing `favoriteOrder = position`. Returns ONLY the rows whose order
    /// changed (empty when the move is out of bounds).
    static func moveFavorite(_ channels: [ChannelEntity], channelId: Int, delta: Int) -> [ChannelEntity] {
        guard let reordered = swapped(favorites(channels), channelId: channelId, delta: delta) else {
            return []
        }
        var changed: [ChannelEntity] = []
        for (index, channel) in reordered.enumerated() where channel.flags.favoriteOrder != index {
            var updated = channel
            updated.flags.favoriteOrder = index
            changed.append(updated)
        }
        return changed
    }

    /// Swaps a channel with its neighbour in an already-ordered group list by
    /// exchanging their `sortIndex`. Returns the two changed rows (empty when
    /// out of bounds).
    static func moveInGroup(_ ordered: [ChannelEntity], channelId: Int, delta: Int) -> [ChannelEntity] {
        guard let from = ordered.firstIndex(where: { $0.id == channelId }) else { return [] }
        let to = from + delta
        guard ordered.indices.contains(to) else { return [] }
        var moved = ordered[from], neighbour = ordered[to]
        (moved.sortIndex, neighbour.sortIndex) = (neighbour.sortIndex, moved.sortIndex)
        return [moved, neighbour]
    }

    /// A bounds-checked positional swap of `channelId` with its `delta`
    /// neighbour, returning the reordered array or nil if out of bounds.
    private static func swapped(_ ordered: [ChannelEntity], channelId: Int,
                                delta: Int) -> [ChannelEntity]? {
        guard let from = ordered.firstIndex(where: { $0.id == channelId }) else { return nil }
        let to = from + delta
        guard ordered.indices.contains(to) else { return nil }
        var result = ordered
        result.swapAt(from, to)
        return result
    }
}
