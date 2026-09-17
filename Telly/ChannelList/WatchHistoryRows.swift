/// Pure join of watch-history events onto the visible channels — the Apple
/// mirror of Android `HistoryRows`. The store returns raw events (keys only);
/// this resolves each `channelKey` to its current `ChannelEntity` via
/// `ChannelImporter.keyOf`, preserving newest-first order and dropping keys
/// with no visible channel (unresolved after a refresh removed them).
enum WatchHistoryRows {
    static func rows(events: [WatchHistoryEntry], channels: [ChannelEntity]) -> [ChannelEntity] {
        let byKey = Dictionary(channels.map { (ChannelImporter.keyOf($0), $0) },
                               uniquingKeysWith: { _, last in last })
        return events.compactMap { byKey[$0.channelKey] }
    }
}
