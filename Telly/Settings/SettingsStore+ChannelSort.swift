import Foundation

/// The persisted channel-list sort order over the backing ``KeyValueStore``.
/// Mirrors the `+Appearance` tracked-mirror idiom: `channelSortRaw` is what the
/// Settings picker binds to (get returns the tracked var, set writes through so
/// SwiftUI observes the change and the list/guide re-order live); `channelSort`
/// derives the typed mode the channel list, panel and guide rows order by.
/// Corrupt / out-of-range raws coerce to `.default` (playlist order).
extension SettingsStore {
    /// The stored sort-mode raw value the Settings picker binds to.
    var channelSortRaw: Int {
        get { rawChannelSort }
        set { rawChannelSort = newValue; backing.writeInt(newValue, SettingsKey.channelSort.rawValue) }
    }

    /// The derived channel-list sort mode applied across the channel surfaces.
    var channelSort: ChannelSort { .from(channelSortRaw) }
}
