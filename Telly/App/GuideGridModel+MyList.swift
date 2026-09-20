import Foundation

/// The guide cell's My List add/remove logic — the Apple mirror of the My List
/// row in Android's `GuideScreenCellMenu` (capture 27), reusing the SAME shared
/// ``MyListToggling`` over the injected ``MyListStore`` as the Search entry point
/// (no parallel toggle path). A nil store makes every call a no-op.
extension GuideGridModel {
    /// Whether the cell's programme is already saved (drives the menu label).
    func isSaved(channel: ChannelEntity, cell: GuideCell) -> Bool {
        guard let program = cell.program else { return false }
        return MyListToggle.isSaved(keys: myListKeys, channelKey: ChannelImporter.keyOf(channel),
                                    startMs: program.startMs)
    }

    /// Saves the cell's programme, or removes it when already saved, then reloads keys.
    func toggleMyList(channel: ChannelEntity, cell: GuideCell) {
        guard let store = myListStore, let program = cell.program else { return }
        MyListToggling.apply(store: store, saved: isSaved(channel: channel, cell: cell),
            channelKey: ChannelImporter.keyOf(channel), title: program.details.title,
            description: program.details.description, startMs: program.startMs,
            endMs: program.endMs, addedAtMs: now())
        refreshMyListKeys()
    }

    /// Reloads `myListKeys` from the store (the live saved-state the label reads).
    func refreshMyListKeys() { myListKeys = MyListToggling.keys(from: myListStore) }
}
