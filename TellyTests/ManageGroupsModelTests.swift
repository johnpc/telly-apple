import Testing
import GRDB
@testable import Telly

/// The Manage-Groups editor model against a REAL in-memory GRDB database: create
/// adds an EMPTY group and reloads the feed, a blank/whitespace name is ignored
/// on both create and rename, rename reflects in `groups`, and delete removes the
/// group. Sibling of ``CustomGroupStoreTests``.
@MainActor
struct ManageGroupsModelTests {
    private func model() throws -> ManageGroupsModel {
        ManageGroupsModel(store: CustomGroupStore(db: try AppDatabase.makeInMemory()))
    }

    @Test func createAddsGroupAndReloads() throws {
        let model = try model()
        model.load()
        model.create("News")
        #expect(model.groups.map(\.name) == ["News"])
    }

    @Test func createIgnoresBlankName() throws {
        let model = try model()
        model.create("   ")
        #expect(model.groups.isEmpty)
    }

    @Test func renameReflectsInGroups() throws {
        let model = try model()
        model.create("Old")
        let id = try #require(model.groups.first?.id)
        model.rename(id: id, "New")
        #expect(model.groups.map(\.name) == ["New"])
    }

    @Test func renameIgnoresBlankName() throws {
        let model = try model()
        model.create("Keep")
        let id = try #require(model.groups.first?.id)
        model.rename(id: id, "  ")
        #expect(model.groups.map(\.name) == ["Keep"])
    }

    @Test func deleteRemovesGroup() throws {
        let model = try model()
        model.create("A")
        model.create("B")
        let id = try #require(model.groups.first?.id)
        model.delete(id: id)
        #expect(model.groups.map(\.name) == ["B"])
    }
}
