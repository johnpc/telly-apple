import Foundation

/// A live stream row (`get_live_streams`). `epgChannelId` is preserved as the
/// channel's tvg-id so the XMLTV guide matches; `tvArchive` flags catch-up.
/// Decoded with `.convertFromSnakeCase` (no hand-written `CodingKeys`).
struct XtreamLiveStream: Decodable {
    let streamId: Int
    let name: String
    let streamIcon: String?
    let epgChannelId: String?
    let categoryId: String?
    let tvArchive: Int?
    let tvArchiveDuration: Int?
}

/// A VOD/movie row (`get_vod_streams`). `containerExtension` yields a
/// file-extension stream URL so the shared importer partitions it into VOD.
struct XtreamVodStream: Decodable {
    let streamId: Int
    let name: String
    let streamIcon: String?
    let categoryId: String?
    let containerExtension: String?
}
