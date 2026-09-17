import Foundation

/// Derives the distinct group list of a playlist from its channels — the source
/// of truth the per-playlist Manage-groups pane toggles and the cascade planner
/// share. Pure: names are read straight off `ChannelSource.groupTitle`, in
/// first-appearance order, with blank/absent groups dropped and each name
/// surfaced once.
enum ChannelGroups {
    /// The non-empty group titles of `channels`, de-duplicated, keeping the
    /// order each first appears (channels arrive in channel-number order).
    static func names(_ channels: [ChannelEntity]) -> [String] {
        var seen = Set<String>()
        var ordered: [String] = []
        for channel in channels {
            guard let group = channel.source.groupTitle, !group.isEmpty else { continue }
            if seen.insert(group).inserted { ordered.append(group) }
        }
        return ordered
    }
}
