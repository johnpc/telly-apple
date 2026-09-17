import Foundation

/// Plans the set of preference keys a single playlist owns, so a URL change can
/// migrate them and a delete can purge them without leaving orphaned keys in the
/// flat ``KeyValueStore``. Pure: it only assembles key strings from
/// ``PlaylistSettingsKeys`` given the playlist URL and its group names.
enum PlaylistKeyPlan {
    /// The per-playlist scalar keys (auto-refresh interval, update-on-start and
    /// the enabled flag) — the settings that exist independent of any group.
    static func scalarKeys(_ url: String) -> [String] {
        [PlaylistSettingsKeys.updateIntervalKey(url),
         PlaylistSettingsKeys.updateOnStartKey(url),
         PlaylistSettingsKeys.enabledKey(url)]
    }

    /// Every key the playlist owns: its scalars plus one group-enabled key per
    /// group — the exact set to purge on delete and to clear after a URL change.
    static func allKeys(_ url: String, groups: [String]) -> [String] {
        scalarKeys(url) + groups.map { PlaylistSettingsKeys.groupEnabledKey(url, group: $0) }
    }
}
