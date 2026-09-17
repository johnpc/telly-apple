import Testing
import GRDB
@testable import Telly

/// The `v7-mylist` migration: a fresh in-memory database carries the `my_list`
/// table and round-trips a saved entry through `MyListStore` (proving the table
/// and its composite key both exist).
struct AppDatabaseTests {
    @Test func v7CreatesMyListTable() throws {
        let db = try AppDatabase.makeInMemory()
        let exists = try db.queue.read { try $0.tableExists("my_list") }
        #expect(exists)
    }

    @Test func v7MyListRoundTripsThroughStore() throws {
        let store = MyListStore(db: try AppDatabase.makeInMemory())
        let e = MyListEntry(channelKey: "a", startMs: 1, endMs: 2,
                            title: "T", description: nil, addedAtMs: 3)
        try store.save(e)
        #expect(try store.all() == [e])
    }
}
