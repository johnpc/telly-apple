import Testing
import GRDB
@testable import Telly

/// VOD item persistence against a REAL in-memory GRDB database (the additive
/// `v6-vod` migration must have created `vod_items`): insert round-trips through
/// `byKey`/`totalCount`, `all()` orders by sortIndex, and `replace(playlistId:)`
/// swaps exactly one playlist's rows without touching another's.
struct VodItemStoreTests {
    private func store() throws -> VodItemStore {
        VodItemStore(db: try AppDatabase.makeInMemory())
    }

    private func item(_ playlistId: Int, _ index: Int, _ key: String) -> VodItem {
        VodItem(id: nil, playlistId: playlistId, sortIndex: index, itemKey: key,
                name: "Movie \(key)", groupTitle: "Action", logoUrl: nil,
                streamUrl: "http://x/\(key).mp4")
    }

    @Test func insertRoundTripsThroughByKeyAndCount() throws {
        let store = try store()
        try store.replace(playlistId: 1, items: [item(1, 0, "a"), item(1, 1, "b")])
        #expect(try store.totalCount() == 2)
        let found = try #require(try store.byKey("b"))
        #expect(found.name == "Movie b")
        #expect(found.streamUrl == "http://x/b.mp4")
        #expect(try store.byKey("missing") == nil)
    }

    @Test func allOrdersBySortIndex() throws {
        let store = try store()
        try store.replace(playlistId: 1, items: [item(1, 5, "late"), item(1, 0, "early")])
        #expect(try store.all().map(\.itemKey) == ["early", "late"])
    }

    @Test func replaceOnlyAffectsThatPlaylist() throws {
        let store = try store()
        try store.replace(playlistId: 1, items: [item(1, 0, "a1")])
        try store.replace(playlistId: 2, items: [item(2, 0, "b1")])
        try store.replace(playlistId: 1, items: [item(1, 0, "a2")])
        #expect(try store.all().map(\.itemKey).sorted() == ["a2", "b1"])
        #expect(try store.totalCount() == 2)
    }
}
