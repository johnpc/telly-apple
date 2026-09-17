import Testing
import GRDB
@testable import Telly

/// Resume-position persistence against a REAL in-memory GRDB database. Covers
/// the "Remember playback position" gate (off => no-op read/save), the mid-band
/// upsert, the finished (>95%) delete, the unknown-duration guard, and clear().
struct VodPositionStoreTests {
    private func store(remember: Bool = true, now: Int64 = 100) throws -> VodPositionStore {
        VodPositionStore(db: try AppDatabase.makeInMemory(), remember: { remember }, clock: { now })
    }

    @Test func rememberOffReadsNilAndSkipsSave() throws {
        let db = try AppDatabase.makeInMemory()
        let off = VodPositionStore(db: db, remember: { false }, clock: { 1 })
        try off.save(itemKey: "k", positionMs: 500, durationMs: 1000)
        #expect(try off.read(itemKey: "k") == nil)
        // Even with a remembering reader over the same DB, nothing was written.
        let on = VodPositionStore(db: db, remember: { true }, clock: { 1 })
        #expect(try on.all().isEmpty)
    }

    @Test func midBandSaveUpserts() throws {
        let store = try store(now: 777)
        try store.save(itemKey: "k", positionMs: 500, durationMs: 1000)
        var stored = try #require(try store.read(itemKey: "k"))
        #expect(stored == VodPosition(itemKey: "k", positionMs: 500, durationMs: 1000, updatedAtMs: 777))
        try store.save(itemKey: "k", positionMs: 600, durationMs: 1000)
        stored = try #require(try store.read(itemKey: "k"))
        #expect(stored.positionMs == 600)
        #expect(try store.all().count == 1)
    }

    @Test func finishedDeletesTheRow() throws {
        let store = try store()
        try store.save(itemKey: "k", positionMs: 300, durationMs: 1000)
        try store.finish(itemKey: "k", durationMs: 1000)
        #expect(try store.read(itemKey: "k") == nil)
    }

    @Test func unknownDurationNeverWrites() throws {
        let store = try store()
        try store.save(itemKey: "k", positionMs: 500, durationMs: 0)
        #expect(try store.all().isEmpty)
    }

    @Test func clearEmptiesAllPositions() throws {
        let store = try store()
        try store.save(itemKey: "a", positionMs: 100, durationMs: 1000)
        try store.save(itemKey: "b", positionMs: 200, durationMs: 1000)
        try store.clear()
        #expect(try store.all().isEmpty)
    }
}
