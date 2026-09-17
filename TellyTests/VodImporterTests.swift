import Testing
@testable import Telly

/// Pure partition + mapping: `split` sends video-extension entries to VOD and
/// everything else to live; `items` maps name/groupTitle/logoUrl/streamUrl and
/// assigns sortIndex + `itemKey` (`streamUrl|name`) in order.
struct VodImporterTests {
    private func channel(_ title: String, _ url: String, logo: String? = nil,
                         group: String? = nil) -> M3uChannel {
        M3uChannel(title: title, streamURL: url, tvgID: nil, tvgName: nil, tvgLogo: logo,
                   groupTitle: group, catchup: nil, catchupSource: nil, catchupDays: nil)
    }

    @Test func splitPartitionsByExtension() throws {
        let entries = [
            channel("A", "http://x/a.mp4"), channel("Live", "http://x/live.ts"),
            channel("B", "http://x/b.mkv"), channel("C", "http://x/c.avi"),
            channel("D", "http://x/d.mov"), channel("Stream", "http://x/s.m3u8")
        ]
        let (vod, live) = VodImporter.split(entries)
        #expect(vod.map(\.title) == ["A", "B", "C", "D"])
        #expect(live.map(\.title) == ["Live", "Stream"])
    }

    @Test func itemsMapFieldsSortIndexAndKey() throws {
        let entries = [
            channel("First", "http://x/first.mp4", logo: "http://x/1.png", group: "Action"),
            channel("Second", "http://x/second.mkv")
        ]
        let items = VodImporter.items(playlistId: 7, parsed: entries)
        #expect(items.map(\.sortIndex) == [0, 1])
        #expect(items.map(\.playlistId) == [7, 7])
        #expect(items[0].name == "First")
        #expect(items[0].groupTitle == "Action")
        #expect(items[0].logoUrl == "http://x/1.png")
        #expect(items[0].streamUrl == "http://x/first.mp4")
        #expect(items[0].itemKey == "http://x/first.mp4|First")
        #expect(items[1].groupTitle == nil)
        #expect(items[1].itemKey == "http://x/second.mkv|Second")
    }
}
