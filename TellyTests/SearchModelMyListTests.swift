import Foundation
import Testing
import GRDB
@testable import Telly

/// The Search programme-row My List entry point (`SearchModel+MyList`): toggling
/// an unsaved hit snapshots it into the shared `my_list` store and flips
/// `isSaved`/`myListKeys`; toggling again removes it; a pre-seeded store surfaces
/// through the tracked keys at init. Real in-memory GRDB is the backend.
@MainActor
struct SearchModelMyListTests {
    private static let atMs = 1_000
    private let utc = TimeZone(identifier: "UTC")!

    private func m(_ name: String) -> M3uChannel {
        M3uChannel(title: name, streamURL: "http://x/\(name)", tvgID: name, tvgName: nil,
                   tvgLogo: nil, groupTitle: "Live", catchup: nil, catchupSource: nil, catchupDays: nil)
    }

    private func makeModel(_ db: AppDatabase, store: MyListStore) throws -> SearchModel {
        _ = try PlaylistStore(db: db).add(sourceUrl: "u",
                                          playlist: M3uPlaylist(channels: [m("News")]),
                                          name: nil, nowMs: 0)
        let programStore = ProgramStore(db: db)
        try programStore.upsertReplacing(
            document: XmltvDocument(channels: [], programs: [
                XmltvProgram(channelId: "News", startMs: 900, endMs: 1_500,
                             details: ProgramDetails(title: "News Live"))]),
            keepDescriptions: true)
        let repo = SearchRepository(channelStore: ChannelStore(db: db), programStore: programStore,
                                    epg: EpgRepository(store: programStore))
        return SearchModel(repository: repo, history: SearchHistory(store: InMemoryKeyValueStore()),
                           now: { Self.atMs }, timeZone: utc, myListStore: store)
    }

    private func firstHit(_ model: SearchModel) -> SearchProgramHit {
        model.query = "news"
        model.search()
        return model.results.programs[0].airings[0]
    }

    @Test func toggleSavesThenRemoves() throws {
        let db = try AppDatabase.makeInMemory()
        let store = MyListStore(db: db)
        let model = try makeModel(db, store: store)
        let hit = firstHit(model)
        let key = MyListToggle.key(channelKey: ChannelImporter.keyOf(hit.channel),
                                   startMs: hit.program.startMs)

        #expect(!model.isSaved(hit))
        model.toggleMyList(hit)
        #expect(model.isSaved(hit))
        #expect(model.myListKeys.contains(key))
        #expect(try store.all().map(\.title) == ["News Live"])

        model.toggleMyList(hit)
        #expect(!model.isSaved(hit))
        #expect(!model.myListKeys.contains(key))
        #expect(try store.all().isEmpty)
    }

    @Test func initReflectsPreSeededStore() throws {
        let db = try AppDatabase.makeInMemory()
        let store = MyListStore(db: db)
        try store.save(MyListToggle.entry(channelKey: "News", title: "News Live", description: nil,
                                          startMs: 900, endMs: 1_500, addedAtMs: 500))
        let model = try makeModel(db, store: store)
        let hit = firstHit(model)
        #expect(model.isSaved(hit))
        #expect(model.myListKeys == [MyListToggle.key(channelKey: "News", startMs: 900)])
    }

    @Test func nilStoreIsNoOp() throws {
        let db = try AppDatabase.makeInMemory()
        let store = MyListStore(db: db)
        let model = try makeModel(db, store: store)
        let hit = firstHit(model)
        // A model with no store wired ignores toggles (the default construction).
        let bare = SearchModel(repository: model.repository, history: model.history,
                               now: { Self.atMs }, timeZone: utc)
        bare.toggleMyList(hit)
        #expect(bare.myListKeys.isEmpty)
        #expect(!bare.isSaved(hit))
    }
}
