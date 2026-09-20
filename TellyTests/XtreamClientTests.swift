import Testing
@testable import Telly

/// The Xtream client + mapper, driven against synthetic FIXTURE JSON via a fake
/// fetcher — no real server or credentials. Covers auth success/failure, category
/// + stream decoding, live channel/group mapping (epg id, logo, catch-up),
/// VOD mapping, and that mapped live URLs still feed the catch-up builder.
struct XtreamClientTests {
    private let creds = XtreamCredentials.parse(server: "http://example.com:8080",
                                                username: "demo", password: "demo")!

    private struct Fixtures {
        static let handshakeOk = #"{"user_info":{"auth":1,"status":"Active"}}"#
        static let handshakeBad = #"{"user_info":{"auth":0,"status":"Disabled"}}"#
        static let liveCats = #"[{"category_id":"1","category_name":"News"},{"category_id":"2","category_name":"Sports"}]"#
        static let liveStreams = """
        [{"stream_id":101,"name":"News One","stream_icon":"http://img/n1.png",\
        "epg_channel_id":"news.one","category_id":"1","tv_archive":1,"tv_archive_duration":7},\
        {"stream_id":102,"name":"Sports HD","stream_icon":"","epg_channel_id":"","category_id":"2","tv_archive":0}]
        """
        static let vodCats = #"[{"category_id":"10","category_name":"Movies"}]"#
        static let vodStreams = """
        [{"stream_id":501,"name":"A Film","stream_icon":"http://img/f.png",\
        "category_id":"10","container_extension":"mkv"}]
        """
    }

    /// Routes each request to its fixture by the `action` query (handshake = none).
    private func client(handshake: String = Fixtures.handshakeOk) -> XtreamClient {
        XtreamClient { url in
            if url.contains("get_live_categories") { return Fixtures.liveCats }
            if url.contains("get_live_streams") { return Fixtures.liveStreams }
            if url.contains("get_vod_categories") { return Fixtures.vodCats }
            if url.contains("get_vod_streams") { return Fixtures.vodStreams }
            return handshake
        }
    }

    @Test func authorizedImportMapsLiveAndVod() async throws {
        let playlist = try await client().importPlaylist(creds)
        #expect(playlist.epgURL == creds.xmltvUrl)
        #expect(playlist.channels.count == 3)
        let news = playlist.channels[0]
        #expect(news.title == "News One")
        #expect(news.streamURL == "http://example.com:8080/live/demo/demo/101.ts")
        #expect(news.tvgID == "news.one")
        #expect(news.tvgLogo == "http://img/n1.png")
        #expect(news.groupTitle == "News")
        #expect(news.catchup == "xc")
        #expect(news.catchupDays == 7)
    }

    @Test func blankFieldsAndNoArchiveMapToNil() async throws {
        let sports = try await client().importPlaylist(creds).channels[1]
        #expect(sports.groupTitle == "Sports")
        #expect(sports.tvgID == nil)
        #expect(sports.tvgLogo == nil)
        #expect(sports.catchup == nil)
    }

    @Test func vodStreamBecomesClassifiedMovie() async throws {
        let movie = try await client().importPlaylist(creds).channels[2]
        #expect(movie.streamURL == "http://example.com:8080/movie/demo/demo/501.mkv")
        #expect(movie.groupTitle == "Movies")
        #expect(movie.catchup == nil)
        #expect(VodClassifier.isVod(movie.streamURL))
    }

    @Test func unauthorizedThrows() async {
        await #expect(throws: XtreamError.unauthorized) {
            try await client(handshake: Fixtures.handshakeBad).importPlaylist(creds)
        }
    }

    @Test func mappedLiveUrlStillBuildsCatchup() async throws {
        let news = try await client().importPlaylist(creds).channels[0]
        #expect(XtreamUrl.build(streamUrl: news.streamURL, startMs: 0, endMs: 60_000) != nil)
    }
}
