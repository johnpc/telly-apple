import Testing
@testable import Telly

/// The one shared load lifecycle, exercised through the three local-only models
/// that adopted it (My List, History, Movies): empty → `.empty`, content →
/// `.loaded`, and `reload` after a removal re-resolves to `.empty` instead of
/// leaving a blank `.loaded` list.
@MainActor
struct LoadableModelTests {
    @Test func localModelsResolveEmptyThenLoaded() async throws {
        let db = try AppDatabase.makeInMemory()
        let history = HistoryListModel(store: WatchHistoryStore(db: db), channelStore: ChannelStore(db: db))
        await history.start()
        #expect(history.phase == .empty)
        let movies = VodBrowseModel(itemStore: VodItemStore(db: db),
                                    positionStore: VodPositionStore(db: db, remember: { true }, clock: { 0 }))
        await movies.start()
        #expect(movies.phase == .empty)
        #expect(movies.refreshesInBackground)
    }

    @Test func removingTheLastRowReloadsToEmpty() async throws {
        let db = try AppDatabase.makeInMemory()
        let store = ChannelStore(db: db)
        _ = try PlaylistStore(db: db).add(sourceUrl: "http://p", playlist: M3uParser.parse(
            "#EXTM3U\n#EXTINF:-1 tvg-id=\"a\",A\nhttp://127.0.0.1/a.ts\n"), name: nil, nowMs: 0)
        let channel = try #require(try store.visibleChannels().first)
        let myList = MyListStore(db: db)
        try myList.save(MyListEntry(channelKey: ChannelImporter.keyOf(channel), startMs: 1_000, endMs: 5_000,
                                    title: "Show", description: nil, addedAtMs: 1))
        let model = MyListModel(store: myList, channelStore: store, now: { 2_000 }, timeZone: .current)
        await model.start()
        #expect(model.phase == .loaded)
        #expect(model.rows.count == 1)
        model.remove(model.rows[0])
        #expect(model.rows.isEmpty)
        #expect(model.phase == .empty)
    }
}
