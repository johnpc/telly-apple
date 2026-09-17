import Testing
import GRDB
@testable import Telly

/// The pollution fix: a MIXED playlist (mp4/mkv movies interleaved with live
/// streams) must import movies into `vod_items` and live streams into
/// `channels` — and crucially VOD must NOT appear in the channel list/guide.
struct PlaylistStoreVodTests {
    private func channel(_ title: String, _ url: String, group: String? = nil) -> M3uChannel {
        M3uChannel(title: title, streamURL: url, tvgID: nil, tvgName: nil, tvgLogo: nil,
                   groupTitle: group, catchup: nil, catchupSource: nil, catchupDays: nil)
    }

    @Test func mixedPlaylistPartitionsVodFromLive() throws {
        let db = try AppDatabase.makeInMemory()
        let playlists = PlaylistStore(db: db)
        let channels = ChannelStore(db: db)
        let vodItems = VodItemStore(db: db)
        let m3u = M3uPlaylist(epgURL: nil, channels: [
            channel("News", "http://x/news.ts", group: "Live"),
            channel("The Matrix", "http://x/matrix.mp4", group: "Movies"),
            channel("Sports", "http://x/sports.m3u8", group: "Live"),
            channel("Inception", "http://x/inception.mkv", group: "Movies")
        ])
        let id = try playlists.add(sourceUrl: "http://p/list.m3u", playlist: m3u, name: "Mix", nowMs: 1)

        // Live streams landed in channels; movies did NOT.
        let liveNames = try channels.channels(playlistId: Int(id)).map(\.source.name)
        #expect(liveNames == ["News", "Sports"])
        #expect(try channels.totalCount() == 2)

        // Movies landed in vod_items, keyed by streamUrl|name.
        #expect(try vodItems.totalCount() == 2)
        #expect(try vodItems.all().map(\.name) == ["The Matrix", "Inception"])
        #expect(try vodItems.byKey("http://x/matrix.mp4|The Matrix") != nil)
    }

    @Test func reAddReplacesThatPlaylistsVod() throws {
        let db = try AppDatabase.makeInMemory()
        let playlists = PlaylistStore(db: db)
        let vodItems = VodItemStore(db: db)
        let url = "http://p/list.m3u"
        _ = try playlists.add(sourceUrl: url,
            playlist: M3uPlaylist(epgURL: nil, channels: [channel("Old", "http://x/old.mp4")]),
            name: nil, nowMs: 1)
        _ = try playlists.add(sourceUrl: url,
            playlist: M3uPlaylist(epgURL: nil, channels: [channel("New", "http://x/new.mp4")]),
            name: nil, nowMs: 2)
        #expect(try vodItems.all().map(\.name) == ["New"])
    }
}
