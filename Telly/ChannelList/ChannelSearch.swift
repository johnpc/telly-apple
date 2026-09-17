import Foundation

/// Pure name/number filtering over the channel list — a NEW filter dimension the
/// ``ChannelListModel`` composes with the group filter. An empty or
/// whitespace-only query matches everything (order preserved); otherwise a
/// channel matches when its display name contains the query (case- and
/// diacritic-insensitively), or — for an all-digit query — its channel number
/// begins with the query, so "1" finds 1, 10, 12. Dependency-free, mirroring
/// ``ChannelPanelGroups``/``ChannelReorder``.
enum ChannelSearch {
    /// Whether `channel` matches `query` by name or number (see type doc).
    static func matches(_ query: String, _ channel: ChannelEntity) -> Bool {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return true }
        return matchesName(q, channel) || matchesNumber(q, channel)
    }

    /// The channels matching `query`, preserving their original order.
    static func filter(_ channels: [ChannelEntity], query: String) -> [ChannelEntity] {
        channels.filter { matches(query, $0) }
    }

    private static func matchesName(_ q: String, _ channel: ChannelEntity) -> Bool {
        channel.displayName.range(of: q, options: [.caseInsensitive, .diacriticInsensitive]) != nil
    }

    private static func matchesNumber(_ q: String, _ channel: ChannelEntity) -> Bool {
        q.allSatisfy(\.isNumber) && String(channel.number).hasPrefix(q)
    }
}
