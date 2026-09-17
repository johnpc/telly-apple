import Foundation

/// The My List add/remove affordance on Search programme rows — the Apple mirror
/// of Android `SearchProgramMenu.ADD_TO_MY_LIST`, the one surface today that
/// enumerates individual programmes. Toggling snapshots the airing into (or
/// removes it from) the injected ``MyListStore`` then refreshes the tracked
/// `myListKeys` set so the bookmark glyph reflects the store. A nil store (the
/// default) makes every entry point a no-op.
extension SearchModel {
    /// Whether this airing is already in My List (drives the bookmark glyph).
    func isSaved(_ hit: SearchProgramHit) -> Bool {
        MyListToggle.isSaved(keys: myListKeys, channelKey: ChannelImporter.keyOf(hit.channel),
                             startMs: hit.program.startMs)
    }

    /// Saves the airing, or removes it when already saved, then reloads the keys.
    func toggleMyList(_ hit: SearchProgramHit) {
        guard let store = myListStore else { return }
        let channelKey = ChannelImporter.keyOf(hit.channel)
        if isSaved(hit) {
            try? store.remove(channelKey: channelKey, startMs: hit.program.startMs)
        } else {
            try? store.save(MyListToggle.entry(
                channelKey: channelKey, title: hit.title,
                description: hit.program.details.description,
                startMs: hit.program.startMs, endMs: hit.program.endMs, addedAtMs: now()))
        }
        refreshMyListKeys()
    }

    /// Reloads `myListKeys` from the store (the live saved-state the glyph reads).
    func refreshMyListKeys() {
        guard let store = myListStore else { return }
        myListKeys = Set(((try? store.all()) ?? []).map {
            MyListToggle.key(channelKey: $0.channelKey, startMs: $0.startMs)
        })
    }
}
