import Foundation

/// Surfaces user-created custom groups in the group strips — the Apple mirror of
/// Android appending custom groups to the guide/panel group columns. Pure and
/// leaf: names are appended AFTER the playlist groups, and membership resolves
/// through the refresh-stable ``ChannelImporter/keyOf(_:)`` so a group shows
/// exactly its member channels regardless of playlist refreshes.
enum CustomGroupChannels {
    /// The custom-group names in `sortIndex` order (as `CustomGroupStore.all()`
    /// already returns them), appended after the playlist groups.
    static func names(_ customs: [CustomGroup]) -> [String] {
        customs.map(\.name)
    }

    /// The channels whose refresh-stable key is in `memberKeys`, preserving the
    /// input channel order (non-members dropped).
    static func channels(_ all: [ChannelEntity], memberKeys: Set<String>) -> [ChannelEntity] {
        all.filter { memberKeys.contains(ChannelImporter.keyOf($0)) }
    }

    /// The member-key set of the custom group named `named`, or nil when no such
    /// custom group exists (so callers can fall back to playlist-group logic).
    static func members(named: String, in customs: [CustomGroup]) -> Set<String>? {
        customs.first { $0.name == named }?.members
    }
}
