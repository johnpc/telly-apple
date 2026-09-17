/// Pure toggle logic for the My List add/remove affordance — the Apple mirror
/// of Android `MyListKeys` + `MyListMenu.entryOf`. `key` derives the identity
/// string a live `keys` set is keyed by; `isSaved` tests membership; `label`
/// flips the menu title; `entry` snapshots a programme into a `MyListEntry`.
enum MyListToggle {
    /// The identity string for one airing: `"channelKey|startMs"`.
    static func key(channelKey: String, startMs: Int) -> String {
        "\(channelKey)|\(startMs)"
    }

    /// Whether `(channelKey, startMs)` is present in the live `keys` set.
    static func isSaved(keys: Set<String>, channelKey: String, startMs: Int) -> Bool {
        keys.contains(key(channelKey: channelKey, startMs: startMs))
    }

    /// The menu title, flipping on whether the airing is already saved.
    static func label(saved: Bool) -> String {
        saved ? "Remove from My List" : "Add to My List"
    }

    /// Snapshots a programme's fields into a savable `MyListEntry`.
    static func entry(channelKey: String, title: String, description: String?,
                      startMs: Int, endMs: Int, addedAtMs: Int) -> MyListEntry {
        MyListEntry(channelKey: channelKey, startMs: startMs, endMs: endMs,
                    title: title, description: description, addedAtMs: addedAtMs)
    }
}
