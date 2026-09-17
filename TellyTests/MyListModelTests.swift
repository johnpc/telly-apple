import Testing
import Foundation
import GRDB
@testable import Telly

/// The My List screen's model: `load` joins saved programme snapshots
/// (newest-added first) to the visible channels via ``MyListRows`` — dropping
/// keys with no visible channel, hiding ended airings, flagging the one airing
/// now — and `remove` deletes one entry and republishes the remaining rows.
@MainActor
struct MyListModelTests {
    private func seed() throws -> (MyListStore, ChannelStore) {
        let db = try AppDatabase.makeInMemory()
        let playlists = PlaylistStore(db: db)
        let list = M3uPlaylist(channels: [m("A", "aaa"), m("B", "bbb"), m("C", "ccc")])
        _ = try playlists.add(sourceUrl: "u", playlist: list, name: nil, nowMs: 0)
        return (MyListStore(db: db), ChannelStore(db: db))
    }

    private func m(_ name: String, _ tvg: String) -> M3uChannel {
        M3uChannel(title: name, streamURL: "http://x/\(name)", tvgID: tvg, tvgName: nil,
                   tvgLogo: nil, groupTitle: "Live", catchup: nil, catchupSource: nil, catchupDays: nil)
    }

    private func entry(_ key: String, start: Int, end: Int, added: Int) -> MyListEntry {
        MyListEntry(channelKey: key, startMs: start, endMs: end,
                    title: "\(key) show", description: "desc", addedAtMs: added)
    }

    private func model(_ store: MyListStore, _ channels: ChannelStore, now: Int) -> MyListModel {
        MyListModel(store: store, channelStore: channels,
                    now: { now }, timeZone: TimeZone(identifier: "UTC")!)
    }

    @Test func loadJoinsNewestAddedFirstToVisibleChannels() throws {
        let (store, channels) = try seed()
        try store.save(entry("aaa", start: 0, end: 5000, added: 100))
        try store.save(entry("ccc", start: 0, end: 5000, added: 200))
        try store.save(entry("bbb", start: 0, end: 5000, added: 300))
        let m = model(store, channels, now: 1000)
        m.load()
        #expect(m.rows.map(\.channel.source.name) == ["B", "C", "A"])
    }

    @Test func loadHidesEndedAndDropsUnresolvedKeys() throws {
        let (store, channels) = try seed()
        try store.save(entry("aaa", start: 0, end: 5000, added: 100))   // still airing
        try store.save(entry("bbb", start: 0, end: 500, added: 200))    // ended (endMs <= now)
        try store.save(entry("gone", start: 0, end: 5000, added: 300))  // no visible channel
        let m = model(store, channels, now: 1000)
        m.load()
        #expect(m.rows.map(\.channel.source.name) == ["A"])
    }

    @Test func airingFlagReflectsNow() throws {
        let (store, channels) = try seed()
        try store.save(entry("aaa", start: 0, end: 5000, added: 100))     // airing now
        try store.save(entry("bbb", start: 2000, end: 5000, added: 200))  // future
        let m = model(store, channels, now: 1000)
        m.load()
        let airing = Dictionary(uniqueKeysWithValues: m.rows.map { ($0.channel.source.name, $0.airing) })
        #expect(airing["A"] == true)
        #expect(airing["B"] == false)
    }

    @Test func removeDeletesEntryAndReloads() throws {
        let (store, channels) = try seed()
        try store.save(entry("aaa", start: 0, end: 5000, added: 100))
        try store.save(entry("bbb", start: 0, end: 5000, added: 200))
        let m = model(store, channels, now: 1000)
        m.load()
        #expect(m.rows.count == 2)
        let target = try #require(m.rows.first { $0.channel.source.name == "A" })
        m.remove(target)
        #expect(m.rows.map(\.channel.source.name) == ["B"])
        #expect(try store.all().count == 1)
    }
}
