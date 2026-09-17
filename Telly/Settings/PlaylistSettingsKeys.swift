import Foundation

/// Pure builders for the per-playlist preference keys — the Apple mirror of
/// Android's `PlaylistExtraSettings` / `SettingsRowsPlaylists` key formats. Each
/// key namespaces a scalar setting by the playlist's source URL (and, for group
/// visibility, the group name) so multiple playlists keep independent settings
/// in the flat `KeyValueStore`. The per-playlist User-Agent key is intentionally
/// omitted on Apple (the store is Int/Bool-only; see plan §1.3).
enum PlaylistSettingsKeys {
    /// Hours between auto-refreshes for the playlist at `url` (0 = None).
    static func updateIntervalKey(_ url: String) -> String { "playlist_update_interval:\(url)" }

    /// Whether the playlist at `url` refreshes on app start.
    static func updateOnStartKey(_ url: String) -> String { "playlist_update_on_start:\(url)" }

    /// Whether the playlist at `url` is enabled (its channels visible).
    static func enabledKey(_ url: String) -> String { "playlist_enabled:\(url)" }

    /// Whether `group` within the playlist at `url` is enabled (visible).
    static func groupEnabledKey(_ url: String, group: String) -> String {
        "playlist_group_enabled:\(url):\(group)"
    }

    /// The interval choices (hours) the picker surfaces; 0 = None.
    static let PLAYLIST_INTERVAL_CHOICES = [0, 1, 2, 4, 8, 12, 24]
}
