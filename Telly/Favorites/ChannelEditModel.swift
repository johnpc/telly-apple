import Foundation

/// Manage-Favorites / Reorder-in-group editor state (the Apple port of Android
/// `features/mylist/ChannelEditViewModel`). `group == nil` is Manage-Favorites
/// (toggle + move); a non-nil group is Reorder-in-group (move only). All edits
/// persist through the `ChannelStore` write layer.
@MainActor
@Observable
final class ChannelEditModel {
    let store: ChannelStore
    let group: String?
    var channels: [ChannelEntity] = []

    init(store: ChannelStore, group: String? = nil) {
        self.store = store
        self.group = group
    }

    /// Editor rows: favourites-first in Manage-Favorites mode, else the group's
    /// channels in sort order.
    var rows: [ChannelEntity] {
        guard let group else { return ChannelReorder.editorRows(channels) }
        return ChannelListGroups.channels(channels, in: group)
    }

    /// Whether this editor toggles favourites (Manage-Favorites mode only).
    var togglesFavorites: Bool { group == nil }

    func load() { channels = (try? store.visibleChannels()) ?? [] }

    /// Toggles a favourite — a no-op outside Manage-Favorites mode (matching the
    /// Android "OK is inert in reorder-in-group" behaviour).
    func toggle(_ channel: ChannelEntity) {
        guard togglesFavorites else { return }
        try? store.update(ChannelReorder.toggled(channels, channel))
        load()
    }
}
