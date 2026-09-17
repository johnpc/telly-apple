import Testing
import GRDB
@testable import Telly

/// The manual playlist update core: re-import on success (flags survive),
/// per-URL failure isolation (stored copy untouched), and `updateAll` reporting
/// only the successful URLs. Uses an in-memory DB + a fake fetcher.
struct PlaylistUpdaterTests {
    private let good = "http://127.0.0.1:8000/a/playlist.m3u"
    private let bad = "http://127.0.0.1:8000/b/playlist.m3u"

    private struct FetchFailed: Error {}

    private func m3u(_ names: [String]) -> String {
        var text = "#EXTM3U\n"
        for name in names {
            text += "#EXTINF:-1 tvg-id=\"\(name)\",\(name)\nhttp://127.0.0.1:8000/\(name)\n"
        }
        return text
    }

    private func fixture() throws -> (AppDatabase, PlaylistStore, ChannelStore) {
        let db = try AppDatabase.makeInMemory()
        return (db, PlaylistStore(db: db), ChannelStore(db: db))
    }

    /// Non-async so GRDB's synchronous `write` overload is chosen from the
    /// async test that seeds a user favourite before re-importing.
    private func favorite(_ tvg: String, in db: AppDatabase) throws {
        try db.queue.write { try $0.execute(sql: "UPDATE channels SET favorite = 1 WHERE tvgId = ?", arguments: [tvg]) }
    }

    private func updater(_ store: PlaylistStore,
                         fetch: @escaping (String) async throws -> String) -> PlaylistUpdater {
        PlaylistUpdater(fetch: fetch, store: store, now: { 100 })
    }

    @Test func updateReimportsAndReplacesChannels() async throws {
        let (_, store, channels) = try fixture()
        let id = try store.add(sourceUrl: good, playlist: M3uParser.parse(m3u(["A"])), name: nil, nowMs: 1)
        let up = updater(store) { [m3u] _ in m3u(["A", "B", "C"]) }
        #expect(await up.update(good))
        let rows = try channels.channels(playlistId: Int(id))
        #expect(rows.map(\.source.name) == ["A", "B", "C"])
    }

    @Test func updatePreservesUserFavorite() async throws {
        let (db, store, channels) = try fixture()
        let id = try store.add(sourceUrl: good, playlist: M3uParser.parse(m3u(["A"])), name: nil, nowMs: 1)
        try favorite("A", in: db)
        let up = updater(store) { [m3u] _ in m3u(["A", "B"]) }
        #expect(await up.update(good))
        let rows = try channels.channels(playlistId: Int(id))
        #expect(rows.first { $0.source.name == "A" }?.flags.favorite == true)
    }

    @Test func fetchFailureReturnsFalseAndLeavesStoreUntouched() async throws {
        let (_, store, channels) = try fixture()
        let id = try store.add(sourceUrl: good, playlist: M3uParser.parse(m3u(["A", "B"])), name: nil, nowMs: 1)
        let up = updater(store) { _ in throw FetchFailed() }
        #expect(await up.update(good) == false)
        let rows = try channels.channels(playlistId: Int(id))
        #expect(rows.map(\.source.name) == ["A", "B"])
    }

    @Test func updateAllReturnsOnlySuccessfulUrls() async throws {
        let (_, store, _) = try fixture()
        _ = try store.add(sourceUrl: good, playlist: M3uParser.parse(m3u(["A"])), name: nil, nowMs: 1)
        _ = try store.add(sourceUrl: bad, playlist: M3uParser.parse(m3u(["Z"])), name: nil, nowMs: 1)
        let up = updater(store) { [good, m3u] url in
            if url == good { return m3u(["A", "B"]) }
            throw FetchFailed()
        }
        #expect(await up.updateAll([good, bad]) == [good])
    }
}
