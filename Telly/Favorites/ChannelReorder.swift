import Foundation

/// Pure favourites/reorder math — the Apple port of the Android
/// `features/mylist/ChannelReorder.kt`. No I/O: the store persists the result.
enum ChannelReorder {
    /// The favourite channels in Manage-Favorites order: sorted by
    /// `favoriteOrder`, ties broken by original position. A *stable* sort —
    /// Swift's `sorted(by:)` is not guaranteed stable, so the original index is
    /// folded into the comparison to reproduce Kotlin `sortedBy`'s stability.
    static func favorites(_ channels: [ChannelEntity]) -> [ChannelEntity] {
        channels.enumerated()
            .filter { $0.element.flags.favorite }
            .sorted { lhs, rhs in
                (lhs.element.flags.favoriteOrder, lhs.offset)
                    < (rhs.element.flags.favoriteOrder, rhs.offset)
            }
            .map(\.element)
    }

    /// The Manage-Favorites editor rows: favourites first (in order), then the
    /// remaining channels in their base order.
    static func editorRows(_ channels: [ChannelEntity]) -> [ChannelEntity] {
        favorites(channels) + channels.filter { !$0.flags.favorite }
    }

    /// A copy of `channel` with its favourite flag toggled: adding appends it
    /// after the current favourites (`max favoriteOrder + 1`); removing clears
    /// the flag but keeps the order value (matching Android).
    static func toggled(_ channels: [ChannelEntity], _ channel: ChannelEntity) -> ChannelEntity {
        var result = channel
        if channel.flags.favorite {
            result.flags.favorite = false
        } else {
            result.flags.favorite = true
            result.flags.favoriteOrder = (favorites(channels).map(\.flags.favoriteOrder).max() ?? -1) + 1
        }
        return result
    }
}
