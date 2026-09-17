import Testing
import GRDB
@testable import Telly

/// Custom EPG-source persistence against a REAL in-memory GRDB database (the
/// v4 migration must have created `epg_sources`): add + unique-index dedupe,
/// per-playlist ordering by `addedAtMs`, edit, remove, and playlist re-key.
struct EpgSourceStoreTests {
    private let a = "http://127.0.0.1:8000/a/playlist.m3u"
    private let b = "http://127.0.0.1:8000/b/playlist.m3u"

    private func store() throws -> EpgSourceStore {
        EpgSourceStore(db: try AppDatabase.makeInMemory())
    }

    @Test func addPersistsAndDedupesOnUniqueIndex() throws {
        let store = try store()
        try store.add(playlistUrl: a, url: "http://127.0.0.1:8000/epg.xml", nowMs: 1)
        try store.add(playlistUrl: a, url: "http://127.0.0.1:8000/epg.xml", nowMs: 2)
        let rows = try store.all()
        #expect(rows.count == 1)
        #expect(rows[0].playlistUrl == a)
        #expect(rows[0].url == "http://127.0.0.1:8000/epg.xml")
    }

    @Test func forPlaylistFiltersAndOrdersByAddedAt() throws {
        let store = try store()
        try store.add(playlistUrl: a, url: "http://127.0.0.1:8000/second.xml", nowMs: 20)
        try store.add(playlistUrl: a, url: "http://127.0.0.1:8000/first.xml", nowMs: 10)
        try store.add(playlistUrl: b, url: "http://127.0.0.1:8000/other.xml", nowMs: 5)
        let rows = try store.forPlaylist(a)
        #expect(rows.map(\.url) == ["http://127.0.0.1:8000/first.xml",
                                    "http://127.0.0.1:8000/second.xml"])
    }

    @Test func setUrlUpdatesInPlace() throws {
        let store = try store()
        try store.add(playlistUrl: a, url: "http://127.0.0.1:8000/old.xml", nowMs: 1)
        let id = try #require(store.all().first?.id)
        try store.setUrl(id: id, url: "http://127.0.0.1:8000/new.xml")
        #expect(try store.all().map(\.url) == ["http://127.0.0.1:8000/new.xml"])
    }

    @Test func removeDeletesTheSource() throws {
        let store = try store()
        try store.add(playlistUrl: a, url: "http://127.0.0.1:8000/epg.xml", nowMs: 1)
        let id = try #require(store.all().first?.id)
        try store.remove(id: id)
        #expect(try store.all().isEmpty)
    }

    @Test func rekeyPlaylistMovesRowsFromOldToNew() throws {
        let store = try store()
        try store.add(playlistUrl: a, url: "http://127.0.0.1:8000/epg.xml", nowMs: 1)
        try store.rekeyPlaylist(oldUrl: a, newUrl: b)
        #expect(try store.forPlaylist(a).isEmpty)
        #expect(try store.forPlaylist(b).map(\.url) == ["http://127.0.0.1:8000/epg.xml"])
    }
}
