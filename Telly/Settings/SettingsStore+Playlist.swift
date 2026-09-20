import Foundation

/// Per-playlist typed reads/writes over the backing ``KeyValueStore``, keyed by
/// ``PlaylistSettingsKeys``. Split into its own extension so ``SettingsStore``
/// stays within budget (extension precedent: `+Consumers`, `+Keymap`). An unset
/// key reads back nil from the store, so the Android defaults are applied here:
/// interval 0 ("None"), on-start false, and enabled/group-enabled TRUE (an
/// unconfigured playlist or group shows by default via `?? true`).
extension SettingsStore {
    /// Hours between auto-refreshes for `url` (default 0 = None).
    func updateInterval(url: String) -> Int {
        backing.readInt(PlaylistSettingsKeys.updateIntervalKey(url)) ?? 0
    }

    func setUpdateInterval(url: String, _ hours: Int) {
        backing.writeInt(hours, PlaylistSettingsKeys.updateIntervalKey(url))
    }

    /// Whether `url` refreshes on app start (default false).
    func updateOnStart(url: String) -> Bool {
        backing.readBool(PlaylistSettingsKeys.updateOnStartKey(url)) ?? false
    }

    func setUpdateOnStart(url: String, _ on: Bool) {
        backing.writeBool(on, PlaylistSettingsKeys.updateOnStartKey(url))
    }

    /// Whether `url` is enabled (default TRUE — an unset playlist shows).
    func enabled(url: String) -> Bool {
        backing.readBool(PlaylistSettingsKeys.enabledKey(url)) ?? true
    }

    func setEnabled(url: String, _ on: Bool) {
        backing.writeBool(on, PlaylistSettingsKeys.enabledKey(url))
    }

    /// Whether `group` in `url` is enabled (default TRUE — an unset group shows).
    func groupEnabled(url: String, group: String) -> Bool {
        backing.readBool(PlaylistSettingsKeys.groupEnabledKey(url, group: group)) ?? true
    }

    func setGroupEnabled(url: String, group: String, _ on: Bool) {
        backing.writeBool(on, PlaylistSettingsKeys.groupEnabledKey(url, group: group))
    }

    /// Force a full EPG refresh after any playlist changes (default: false). A
    /// global toggle (not per-`url`) but housed here beside the playlist-update
    /// seams; the tracked mirror lives in the base store so the picker observes it.
    var updateOnPlaylistsChange: Bool {
        get { rawUpdateOnPlaylistsChange }
        set {
            rawUpdateOnPlaylistsChange = newValue
            backing.writeBool(newValue, SettingsKey.updateOnPlaylistsChange.rawValue)
        }
    }
}
