import Foundation

/// Pure mapping from decoded Xtream DTOs into the app's ``M3uPlaylist``, so the
/// entire downstream import/persistence/EPG/catch-up path is reused unchanged.
/// Live streams become live channels (category → group, `epg_channel_id`
/// preserved as tvg-id, `stream_icon` as logo, `catchup="xc"` when the stream
/// has an archive); VOD streams become movies whose file-extension URL the
/// importer partitions into the VOD store. The playlist EPG is `xmltv.php`.
enum XtreamMapper {
    static func playlist(credentials: XtreamCredentials,
                         liveCategories: [XtreamCategory], liveStreams: [XtreamLiveStream],
                         vodCategories: [XtreamCategory], vodStreams: [XtreamVodStream]) -> M3uPlaylist {
        let live = liveStreams.map { channel($0, credentials, names(liveCategories)) }
        let vod = vodStreams.map { movie($0, credentials, names(vodCategories)) }
        return M3uPlaylist(epgURL: credentials.xmltvUrl, channels: live + vod)
    }

    private static func names(_ categories: [XtreamCategory]) -> [String: String] {
        Dictionary(categories.map { ($0.categoryId, $0.categoryName) }, uniquingKeysWith: { first, _ in first })
    }

    private static func channel(_ stream: XtreamLiveStream, _ creds: XtreamCredentials,
                                _ groups: [String: String]) -> M3uChannel {
        let archived = (stream.tvArchive ?? 0) == 1
        return M3uChannel(
            title: stream.name, streamURL: creds.liveUrl(streamId: stream.streamId),
            tvgID: stream.epgChannelId?.nonBlank, tvgName: nil, tvgLogo: stream.streamIcon?.nonBlank,
            groupTitle: stream.categoryId.flatMap { groups[$0] },
            catchup: archived ? "xc" : nil, catchupSource: nil,
            catchupDays: archived ? stream.tvArchiveDuration : nil)
    }

    private static func movie(_ stream: XtreamVodStream, _ creds: XtreamCredentials,
                              _ groups: [String: String]) -> M3uChannel {
        M3uChannel(
            title: stream.name,
            streamURL: creds.movieUrl(streamId: stream.streamId, ext: stream.containerExtension?.nonBlank ?? "mp4"),
            tvgID: nil, tvgName: nil, tvgLogo: stream.streamIcon?.nonBlank,
            groupTitle: stream.categoryId.flatMap { groups[$0] },
            catchup: nil, catchupSource: nil, catchupDays: nil)
    }
}
