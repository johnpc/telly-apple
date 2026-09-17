import Foundation
import Testing
@testable import Telly

/// Pure join behaviour of `MyListRows`: hide ended airings, drop keys with no
/// visible channel, flag the airing-now row, preserve the store's newest-first
/// order, and stamp each row's air time. UTC keeps the label deterministic.
struct MyListRowsTests {
    private let utc = TimeZone(identifier: "UTC")!

    private func channel(tvgId: String, name: String = "N") -> ChannelEntity {
        ChannelEntity(playlistId: 1, number: 1, sortIndex: 0,
                      source: ChannelSource(name: name, streamUrl: "u", tvgId: tvgId))
    }

    private func entry(_ key: String, start: Int, end: Int) -> MyListEntry {
        MyListEntry(channelKey: key, startMs: start, endMs: end,
                    title: "T", description: nil, addedAtMs: 0)
    }

    @Test func hidesEndedEntriesAtBoundary() throws {
        let rows = MyListRows.rows(entries: [entry("a", start: 0, end: 100)],
                                   channels: [channel(tvgId: "a")], nowMs: 100, timeZone: utc)
        #expect(rows.isEmpty) // endMs (100) is not > nowMs (100)
    }

    @Test func dropsUnresolvedChannelKeys() throws {
        let a = channel(tvgId: "a", name: "Alpha")
        let rows = MyListRows.rows(entries: [entry("gone", start: 0, end: 10_000),
                                             entry("a", start: 0, end: 10_000)],
                                   channels: [a], nowMs: 0, timeZone: utc)
        #expect(rows.map(\.channel.source.name) == ["Alpha"])
    }

    @Test func flagsAiringWithinWindowButNotFuture() throws {
        let a = channel(tvgId: "a")
        let now = MyListRows.rows(entries: [entry("a", start: 100, end: 300)],
                                  channels: [a], nowMs: 200, timeZone: utc)
        let future = MyListRows.rows(entries: [entry("a", start: 500, end: 900)],
                                     channels: [a], nowMs: 200, timeZone: utc)
        #expect(now.first?.airing == true)
        #expect(future.first?.airing == false)
    }

    @Test func preservesInputOrder() throws {
        let a = channel(tvgId: "a", name: "Alpha")
        let b = channel(tvgId: "b", name: "Bravo")
        let rows = MyListRows.rows(
            entries: [entry("b", start: 0, end: 10_000), entry("a", start: 0, end: 10_000)],
            channels: [a, b], nowMs: 0, timeZone: utc)
        #expect(rows.map(\.channel.source.name) == ["Bravo", "Alpha"])
    }

    @Test func stampsAirTimeText() throws {
        // start on 1970-01-02 00:30 UTC → date prefix + single time.
        let start = 86_400_000 + 1_800_000
        let rows = MyListRows.rows(entries: [entry("a", start: start, end: start + 3_600_000)],
                                   channels: [channel(tvgId: "a")], nowMs: 0, timeZone: utc)
        #expect(rows.first?.airTimeText == "Fri, Jan 2, 00:30")
    }
}
