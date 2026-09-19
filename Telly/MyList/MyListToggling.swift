import Foundation

/// Store-side My List operations shared by every add/remove entry point (the
/// Search programme rows, the guide cell menu) so no surface grows its own
/// parallel path over ``MyListStore`` — the Apple mirror of Android `MyListMenu`.
/// Pure over an injected store; a nil store yields the empty key set / a no-op.
enum MyListToggling {
    /// The live saved-airing key set backing every bookmark/label (empty w/o a store).
    static func keys(from store: MyListStore?) -> Set<String> {
        guard let store else { return [] }
        return Set(((try? store.all()) ?? []).map {
            MyListToggle.key(channelKey: $0.channelKey, startMs: $0.startMs)
        })
    }

    /// Adds the airing when not `saved`, else removes it (the composite-PK toggle).
    static func apply(store: MyListStore, saved: Bool, channelKey: String, title: String,
                      description: String?, startMs: Int, endMs: Int, addedAtMs: Int) {
        if saved {
            try? store.remove(channelKey: channelKey, startMs: startMs)
        } else {
            try? store.save(MyListToggle.entry(channelKey: channelKey, title: title,
                description: description, startMs: startMs, endMs: endMs, addedAtMs: addedAtMs))
        }
    }
}
