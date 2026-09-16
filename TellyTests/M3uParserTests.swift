import Testing
@testable import Telly

/// Unit coverage for the M3U parser, ported from the Android `M3uParserTest`.
struct M3uParserTests {

    @Test func detectsHeaderAndExtInf() {
        #expect(M3uParser.isHeader("#EXTM3U url-tvg=\"http://e.pg/x.xml\""))
        #expect(M3uParser.isExtInf("#EXTINF:-1,News"))
        #expect(!M3uParser.isHeader("#EXTINF:-1,News"))
        #expect(!M3uParser.isExtInf("http://stream/1"))
    }

    @Test func headerAttributesReadUrlTvg() {
        let attrs = M3uParser.headerAttributes("#EXTM3U url-tvg=\"http://e.pg/guide.xml\"")
        #expect(attrs["url-tvg"] == "http://e.pg/guide.xml")
        #expect(M3uParser.headerAttributes("#EXTINF:-1,X").isEmpty)
    }

    @Test func parseExtInfExtractsTitleAndAttributes() {
        let line = "#EXTINF:-1 tvg-id=\"n1\" tvg-logo=\"http://l/n.png\" group-title=\"News\",News One"
        let entry = M3uParser.parseExtInf(line)
        #expect(entry?.title == "News One")
        #expect(entry?.attributes["tvg-id"] == "n1")
        #expect(entry?.attributes["group-title"] == "News")
    }

    @Test func parseExtInfRejectsNonExtInfAndEmptyTitle() {
        #expect(M3uParser.parseExtInf("http://stream/1") == nil)
        #expect(M3uParser.parseExtInf("#EXTINF:-1,") == nil)
    }

    @Test func parseBuildsPlaylistWithEpgHintAndChannels() {
        let content = """
        #EXTM3U url-tvg="http://e.pg/guide.xml"
        #EXTINF:-1 tvg-id="n1" group-title="News",News One
        http://stream/news
        # a stray comment
        #EXTINF:-1 tvg-id="s1" group-title="Sports",Sports Arena
        http://stream/sports
        """
        let playlist = M3uParser.parse(content)
        #expect(playlist.epgURL == "http://e.pg/guide.xml")
        #expect(playlist.channels.count == 2)
        #expect(playlist.channels[0].title == "News One")
        #expect(playlist.channels[0].tvgID == "n1")
        #expect(playlist.channels[0].groupTitle == "News")
        #expect(playlist.channels[0].streamURL == "http://stream/news")
        #expect(playlist.channels[1].title == "Sports Arena")
    }

    @Test func parseMapsCatchupAttributesWithLegacyFallback() {
        let content = """
        #EXTM3U
        #EXTINF:-1 catchup-type="shift" catchup-source="http://c/{utc}" catchup-days="7",Arch
        http://stream/arch
        """
        let channel = M3uParser.parse(content).channels[0]
        #expect(channel.catchup == "shift")
        #expect(channel.catchupSource == "http://c/{utc}")
        #expect(channel.catchupDays == 7)
    }

    @Test func parseDropsExtInfWithNoFollowingUrl() {
        let content = """
        #EXTM3U
        #EXTINF:-1,Dangling
        #EXTINF:-1,Real
        http://stream/real
        """
        let playlist = M3uParser.parse(content)
        #expect(playlist.channels.count == 1)
        #expect(playlist.channels[0].title == "Real")
    }
}
