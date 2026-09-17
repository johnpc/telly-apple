import Foundation

/// Pure helpers for copying channels into a custom group — the Apple port of
/// Android's `CopyChannelsSession`. ``selectableChannels`` drops HIDDEN channels
/// (Android's `filterNot { it.flags.hidden }`); ``keys`` maps the checked
/// channels (by stable ``ChannelEntity/id``) to their refresh-stable membership
/// keys via ``ChannelImporter/keyOf(_:)``; ``defaultTarget`` picks the sole
/// custom group when there is exactly one (Android's `singleOrNull()`). Leaf: no
/// dependencies, no I/O.
enum CopyChannelsPlan {
    /// The channels a copy operation may pick from: every channel except HIDDEN
    /// ones, preserving order (Android excludes hidden channels from the list).
    static func selectableChannels(_ all: [ChannelEntity]) -> [ChannelEntity] {
        all.filter { !$0.flags.hidden }
    }

    /// The membership keys for the checked channels (identified by
    /// ``ChannelEntity/id``), in list order, via ``ChannelImporter/keyOf(_:)``.
    static func keys(of selected: Set<Int>, in channels: [ChannelEntity]) -> [String] {
        channels.filter { selected.contains($0.id) }.map(ChannelImporter.keyOf)
    }

    /// The single custom group when exactly one exists (so the target picker is
    /// skipped), else nil — Android's `singleOrNull()`.
    static func defaultTarget(_ groups: [CustomGroup]) -> CustomGroup? {
        groups.count == 1 ? groups.first : nil
    }
}
