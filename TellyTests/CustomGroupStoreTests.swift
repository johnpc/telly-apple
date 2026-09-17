import Testing
import GRDB
@testable import Telly

/// Custom-group persistence against a REAL in-memory GRDB database (the
/// additive `v5-custom-groups` migration must have created the two tables):
/// create assigns increasing sortIndex + returns the new id, rename reflects in
/// `all()`, delete cascades membership, addMembers dedupes, and `all()` joins
/// membership while ordering groups by sortIndex.
struct CustomGroupStoreTests {
    private func store() throws -> CustomGroupStore {
        CustomGroupStore(db: try AppDatabase.makeInMemory())
    }

    @Test func createAssignsIncreasingSortIndexAndReturnsId() throws {
        let store = try store()
        let first = try store.create(name: "News")
        let second = try store.create(name: "Sports")
        #expect(first != second)
        let groups = try store.all()
        #expect(groups.map(\.name) == ["News", "Sports"])
        #expect(groups.map(\.id) == [first, second])
    }

    @Test func allOrdersBySortIndex() throws {
        let store = try store()
        _ = try store.create(name: "A")
        _ = try store.create(name: "B")
        _ = try store.create(name: "C")
        #expect(try store.all().map(\.name) == ["A", "B", "C"])
    }

    @Test func renameReflectsInAll() throws {
        let store = try store()
        let id = try store.create(name: "Old")
        try store.rename(id: id, name: "New")
        #expect(try store.all() == [CustomGroup(id: id, name: "New", members: [])])
    }

    @Test func addMembersJoinsAndDedupes() throws {
        let store = try store()
        let id = try store.create(name: "Kids")
        try store.addMembers(id: id, keys: ["a", "b"])
        try store.addMembers(id: id, keys: ["b", "c"])
        let group = try #require(try store.all().first)
        #expect(group.members == ["a", "b", "c"])
    }

    @Test func addMembersReAddIsNoOp() throws {
        let store = try store()
        let id = try store.create(name: "Kids")
        try store.addMembers(id: id, keys: ["x"])
        try store.addMembers(id: id, keys: ["x"])
        #expect(try store.all().first?.members == ["x"])
    }

    @Test func deleteCascadesMembers() throws {
        let store = try store()
        let keep = try store.create(name: "Keep")
        let drop = try store.create(name: "Drop")
        try store.addMembers(id: keep, keys: ["k1"])
        try store.addMembers(id: drop, keys: ["d1", "d2"])
        try store.delete(id: drop)
        let groups = try store.all()
        #expect(groups.map(\.name) == ["Keep"])
        #expect(groups.first?.members == ["k1"])
        // The dropped group's membership rows are gone (no orphan resurrection).
        let orphans = try store.db.queue.read {
            try Int.fetchOne($0, sql: "SELECT COUNT(*) FROM custom_group_members WHERE groupId = ?",
                             arguments: [drop]) ?? 0
        }
        #expect(orphans == 0)
    }
}
