import Foundation

/// One resolved My List row: the saved entry, the channel it references (looked
/// up live via `ChannelImporter.keyOf`), its air-time stamp, and whether it is
/// airing now (drives the accent tint on the row).
struct MyListRow: Equatable {
    let entry: MyListEntry
    let channel: ChannelEntity
    let airTimeText: String
    let airing: Bool
}

/// Pure join of saved My List entries onto the visible channels — the Apple
/// mirror of Android `MyListRows`. Resolves each `channelKey` to its current
/// `ChannelEntity` via `ChannelImporter.keyOf` (dropping keys with no visible
/// channel, the History precedent), hides ended airings (`endMs > nowMs`),
/// flags the one airing now, stamps each with a `SearchAirTime` air-time label,
/// and preserves the store's newest-added-first order.
enum MyListRows {
    static func rows(entries: [MyListEntry], channels: [ChannelEntity],
                     nowMs: Int, timeZone: TimeZone) -> [MyListRow] {
        let byKey = Dictionary(channels.map { (ChannelImporter.keyOf($0), $0) },
                               uniquingKeysWith: { _, last in last })
        return entries.compactMap { entry in
            guard let channel = byKey[entry.channelKey], entry.endMs > nowMs else { return nil }
            return MyListRow(entry: entry, channel: channel,
                             airTimeText: SearchAirTime.stamp(atMs: entry.startMs, timeZone: timeZone),
                             airing: entry.startMs <= nowMs && nowMs < entry.endMs)
        }
    }
}
