import Testing
@testable import Telly

/// Pure join behaviour of `WatchHistoryRows`: newest-first order preserved from
/// the event list, and events whose `channelKey` no longer resolves to a
/// visible channel are dropped.
struct WatchHistoryRowsTests {
    private func channel(tvgId: String, name: String = "N", url: String = "u") -> ChannelEntity {
        ChannelEntity(playlistId: 1, number: 1, sortIndex: 0,
                      source: ChannelSource(name: name, streamUrl: url, tvgId: tvgId))
    }

    private func event(_ key: String, _ atMs: Int) -> WatchHistoryEntry {
        WatchHistoryEntry(channelKey: key, watchedAtMs: atMs)
    }

    @Test func preservesEventOrderResolvingKeysToChannels() throws {
        let a = channel(tvgId: "a", name: "Alpha")
        let b = channel(tvgId: "b", name: "Bravo")
        let rows = WatchHistoryRows.rows(events: [event("b", 300), event("a", 200)],
                                         channels: [a, b])
        #expect(rows.map(\.source.name) == ["Bravo", "Alpha"])
    }

    @Test func dropsUnresolvedKeys() throws {
        let a = channel(tvgId: "a", name: "Alpha")
        let rows = WatchHistoryRows.rows(events: [event("gone", 300), event("a", 200)],
                                         channels: [a])
        #expect(rows.map(\.source.name) == ["Alpha"])
    }

    @Test func emptyEventsYieldNoRows() throws {
        #expect(WatchHistoryRows.rows(events: [], channels: [channel(tvgId: "a")]).isEmpty)
    }
}
