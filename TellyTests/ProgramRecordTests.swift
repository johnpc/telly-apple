import Testing
import GRDB
@testable import Telly

/// The `programs` schema/migration, the record ↔ domain round-trip, and the
/// load-bearing `(channelTvgId, startMs)` unique index under `.replace`.
struct ProgramRecordTests {
    private func sample(start: Int = 1_000, title: String = "News at Ten") -> ProgramEntity {
        ProgramEntity(
            channelTvgId: "bbc.one",
            startMs: start,
            endMs: start + 3_600_000,
            details: ProgramDetails(title: title, subTitle: "Headlines",
                                    description: "The day's stories.", category: "News",
                                    episode: "S1 E10"))
    }

    private func insert(_ db: AppDatabase, _ entity: ProgramEntity) throws {
        try db.queue.write { var r = ProgramRecord(entity); try r.insert($0, onConflict: .replace) }
    }

    @Test func migrationCreatesTableAndUniqueIndex() throws {
        let db = try AppDatabase.makeInMemory()
        try db.queue.read { d in
            #expect(try d.tableExists("programs"))
            let indexes = try d.indexes(on: "programs")
            let unique = indexes.first { $0.columns == ["channelTvgId", "startMs"] }
            #expect(unique?.isUnique == true)
        }
    }

    @Test func recordRoundTripsThroughDomainEntity() throws {
        let entity = sample()
        #expect(ProgramRecord(entity).entity == entity)
    }

    @Test func assignedRowIdSurfacesAsEntityId() throws {
        let db = try AppDatabase.makeInMemory()
        try insert(db, sample())
        let stored = try db.queue.read { try ProgramRecord.fetchAll($0).map(\.entity) }
        #expect(stored.count == 1)
        #expect(stored[0].id > 0)
        #expect(stored[0].details.title == "News at Ten")
    }

    @Test func duplicateChannelAndStartReplacesKeepingOne() throws {
        let db = try AppDatabase.makeInMemory()
        try insert(db, sample(title: "First"))
        try insert(db, sample(title: "Second"))
        let stored = try db.queue.read { try ProgramRecord.fetchAll($0).map(\.entity) }
        #expect(stored.count == 1)
        #expect(stored[0].details.title == "Second")
    }
}
