import Testing
@testable import Telly

/// The pure processed-step helpers and the shared http(s) URL rules.
struct PlaylistSummaryTests {
    private func channel(_ url: String, group: String? = nil) -> M3uChannel {
        M3uChannel(title: "t", streamURL: url, tvgID: nil, tvgName: nil,
                   tvgLogo: nil, groupTitle: group, catchup: nil, catchupSource: nil, catchupDays: nil)
    }

    @Test func vodClassificationFollowsTheFileExtension() {
        #expect(VodClassifier.isVod("http://x/movie.mp4"))
        #expect(VodClassifier.isVod("http://x/movie.MKV?token=1"))
        #expect(!VodClassifier.isVod("http://x/live.ts"))
        #expect(!VodClassifier.isVod("http://x/live.m3u8"))
        #expect(!VodClassifier.isVod("http://x/nodot"))
    }

    @Test func countsSplitLiveFromMoviesAndCountDistinctGroups() {
        let channels = [channel("http://x/a.ts", group: "News"),
                        channel("http://x/b.ts", group: "News"),
                        channel("http://x/c.mp4", group: "Movies"),
                        channel("http://x/d.mkv", group: "  ")]
        #expect(PlaylistSummary.liveCount(channels) == 2)
        #expect(PlaylistSummary.movieCount(channels) == 2)
        #expect(PlaylistSummary.groupCount(channels) == 2)
    }

    @Test func suggestNameIsTheHostElseTheRawUrl() {
        #expect(PlaylistSummary.suggestName("http://iptv.example.com/iptv/list") == "iptv.example.com")
        #expect(PlaylistSummary.suggestName("garbage") == "garbage")
    }

    @Test func httpUrlAcceptsOnlyHttpSchemesWithHosts() {
        #expect(HttpUrl.isValid("http://a.b/c"))
        #expect(HttpUrl.isValid("https://a.b"))
        #expect(!HttpUrl.isValid("ftp://a.b"))
        #expect(!HttpUrl.isValid("http://"))
        #expect(!HttpUrl.isValid("not a url"))
    }
}
