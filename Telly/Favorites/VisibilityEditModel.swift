import Foundation

/// Bulk "Manage visibility" editor (the Apple port of Android
/// `features/groups/BulkFlagSession`, VISIBILITY kind): every channel, hidden
/// included, with a per-row hidden toggle that persists immediately.
@MainActor
@Observable
final class VisibilityEditModel {
    let store: ChannelStore
    var channels: [ChannelEntity] = []

    init(store: ChannelStore) { self.store = store }

    func load() { channels = (try? store.allChannels()) ?? [] }

    /// Flips a channel's hidden flag, persists it, then reloads.
    func toggleHidden(_ channel: ChannelEntity) {
        var updated = channel
        updated.flags.hidden.toggle()
        try? store.update(updated)
        load()
    }
}
