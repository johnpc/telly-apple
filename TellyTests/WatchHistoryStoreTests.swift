import Testing
import GRDB
@testable import Telly

/// Raw GRDB behaviour of `WatchHistoryStore`: newest-first ordering with
/// PK-replace dedupe (re-watch moves to top), trim-to-`cap`, `recent(limit:)`,
/// and `clear`. Ports the Android `WatchHistoryDaoTest` cases 1:1.
struct WatchHistoryStoreTests {
    private func makeStore() throws -> WatchHistoryStore {
        WatchHistoryStore(db: try AppDatabase.makeInMemory())
    }

    @Test func recentIsNewestFirstAndDedupesToMostRecent() throws {
        let store = try makeStore()
        try store.record(channelKey: "a", atMs: 100)
        try store.record(channelKey: "b", atMs: 200)
        // Re-watching "a" later moves it to the top via PK replace (one row).
        try store.record(channelKey: "a", atMs: 300)
        #expect(try store.recent().map(\.channelKey) == ["a", "b"])
        #expect(try store.recent().map(\.watchedAtMs) == [300, 200])
    }

    @Test func recordTrimsToCapKeepingNewest() throws {
        let store = try makeStore()
        for i in 0..<(WatchHistoryStore.cap + 5) {
            try store.record(channelKey: "ch\(i)", atMs: i)
        }
        let rows = try store.recent(limit: 1_000)
        #expect(rows.count == WatchHistoryStore.cap)
        // The five oldest (ch0..ch4) were trimmed; ch34 is newest.
        #expect(rows.first?.channelKey == "ch\(WatchHistoryStore.cap + 4)")
        #expect(rows.last?.channelKey == "ch5")
    }

    @Test func recentRespectsLimit() throws {
        let store = try makeStore()
        try store.record(channelKey: "a", atMs: 100)
        try store.record(channelKey: "b", atMs: 200)
        try store.record(channelKey: "c", atMs: 300)
        #expect(try store.recent(limit: 2).map(\.channelKey) == ["c", "b"])
    }

    @Test func tieBreaksByChannelKey() throws {
        let store = try makeStore()
        try store.record(channelKey: "b", atMs: 500)
        try store.record(channelKey: "a", atMs: 500)
        #expect(try store.recent().map(\.channelKey) == ["a", "b"])
    }

    @Test func clearEmptiesHistory() throws {
        let store = try makeStore()
        try store.record(channelKey: "a", atMs: 100)
        try store.record(channelKey: "b", atMs: 200)
        try store.clear()
        #expect(try store.recent().isEmpty)
    }
}
