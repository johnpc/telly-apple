import Foundation

/// A single channel entry parsed from an `#EXTINF` playlist line: its display
/// title plus the raw `key="value"` attributes that followed it.
struct M3uEntry: Equatable {
    let title: String
    let attributes: [String: String]
}

/// One live channel: an `#EXTINF` entry paired with its stream URL. Mirrors the
/// Android `M3uChannel` so the import/persistence logic ports 1:1.
struct M3uChannel: Equatable {
    let title: String
    let streamURL: String
    var tvgID: String?
    var tvgName: String?
    var tvgLogo: String?
    var groupTitle: String?
    var catchup: String?
    var catchupSource: String?
    var catchupDays: Int?
}

/// A fully parsed M3U playlist: the optional `url-tvg` EPG hint plus channels.
struct M3uPlaylist: Equatable {
    var epgURL: String?
    var channels: [M3uChannel] = []
}

extension M3uEntry {
    /// Lifts a parsed `#EXTINF` entry into a channel once its URL line arrives.
    func toChannel(streamURL: String) -> M3uChannel {
        M3uChannel(
            title: title,
            streamURL: streamURL,
            tvgID: attributes["tvg-id"],
            tvgName: attributes["tvg-name"],
            tvgLogo: attributes["tvg-logo"],
            groupTitle: attributes["group-title"],
            // Community-standard catch-up attributes; "catchup-type" is the
            // older spelling of "catchup" some providers still emit.
            catchup: attributes["catchup"] ?? attributes["catchup-type"],
            catchupSource: attributes["catchup-source"],
            catchupDays: attributes["catchup-days"].flatMap { Int($0.trimmingCharacters(in: .whitespaces)) }
        )
    }
}
