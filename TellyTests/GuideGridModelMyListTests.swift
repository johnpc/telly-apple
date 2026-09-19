import Testing
import CoreGraphics
import Foundation
import GRDB
@testable import Telly

/// The guide cell's My List entry point (`GuideGridModel+MyList` + the pure
/// `GuideCellActions`): a menu is offered only for an info-carrying, non-airing
/// cell; toggling snapshots that programme into the shared `my_list` store and
/// flips `isSaved`/`myListKeys`; a nil store is a no-op; `load()` reflects a
/// pre-seeded store. Real in-memory GRDB is the backend.
@MainActor
struct GuideGridModelMyListTests {
    static let originMs = 3_600_000

    private func m(_ name: String) -> M3uChannel {
        M3uChannel(title: name, streamURL: "http://x/\(name)", tvgID: name, tvgName: nil,
                   tvgLogo: nil, groupTitle: "G", catchup: nil, catchupSource: nil, catchupDays: nil)
    }

    private func prog(_ ch: String, _ start: Int, _ end: Int, _ title: String) -> XmltvProgram {
        XmltvProgram(channelId: ch, startMs: start, endMs: end,
                     details: ProgramDetails(title: title))
    }

    /// Channels a (Prev/Now/Next around the origin) + c (dataless), loaded at a
    /// fixed UTC clock on the origin, with `store` wired as the My List backend.
    private func makeModel(_ db: AppDatabase, store: MyListStore) throws -> GuideGridModel {
        let o = Self.originMs
        _ = try PlaylistStore(db: db).add(
            sourceUrl: "u", playlist: M3uPlaylist(channels: [m("a"), m("c")]), name: nil, nowMs: 0)
        try ProgramStore(db: db).upsertReplacing(document: XmltvDocument(channels: [], programs: [
            prog("a", o - 1_800_000, o, "PrevA"), prog("a", o, o + 1_800_000, "NowA"),
            prog("a", o + 1_800_000, o + 3_600_000, "NextA")]), keepDescriptions: true)
        let model = GuideGridModel(channelStore: ChannelStore(db: db),
                                   repository: EpgRepository(store: ProgramStore(db: db)),
                                   now: { o }, timeZone: TimeZone(identifier: "UTC")!, is24h: true)
        model.myListStore = store
        model.load()
        return model
    }

    private func rowA(_ model: GuideGridModel) -> GuideRow { model.rows.first { $0.channel.epgId == "a" }! }
    private func cell(_ model: GuideGridModel, _ title: String) -> GuideCell {
        rowA(model).cells.first { $0.program?.details.title == title }!
    }

    @Test func actionsOfferMyListForProgrammeCellsOnly() throws {
        let db = try AppDatabase.makeInMemory()
        let model = try makeModel(db, store: MyListStore(db: db))
        #expect(GuideCellActions.actions(for: cell(model, "NextA")) == [.myList])
        let filler = model.rows.first { $0.channel.epgId == "c" }!.cells.first!
        #expect(GuideCellActions.actions(for: filler).isEmpty)
    }

    @Test func cellMenuTargetOnlyForInfoCells() throws {
        let db = try AppDatabase.makeInMemory()
        let model = try makeModel(db, store: MyListStore(db: db))
        let a = rowA(model)
        // Future cell → menu; airing-now cell tunes (no menu); filler → nil.
        #expect(model.cellMenuTarget(for: cell(model, "NextA"), row: a)?.channel.id == a.channel.id)
        #expect(model.cellMenuTarget(for: cell(model, "NowA"), row: a) == nil)
        let cRow = model.rows.first { $0.channel.epgId == "c" }!
        #expect(model.cellMenuTarget(for: cRow.cells.first!, row: cRow) == nil)
    }

    @Test func toggleSavesThenRemoves() throws {
        let db = try AppDatabase.makeInMemory()
        let store = MyListStore(db: db)
        let model = try makeModel(db, store: store)
        let a = rowA(model)
        let next = cell(model, "NextA")
        let key = MyListToggle.key(channelKey: ChannelImporter.keyOf(a.channel),
                                   startMs: next.program!.startMs)

        #expect(!model.isSaved(channel: a.channel, cell: next))
        model.toggleMyList(channel: a.channel, cell: next)
        #expect(model.isSaved(channel: a.channel, cell: next))
        #expect(model.myListKeys.contains(key))
        #expect(try store.all().map(\.title) == ["NextA"])

        model.toggleMyList(channel: a.channel, cell: next)
        #expect(!model.isSaved(channel: a.channel, cell: next))
        #expect(try store.all().isEmpty)
    }

    @Test func loadReflectsPreSeededStore() throws {
        let db = try AppDatabase.makeInMemory()
        let store = MyListStore(db: db)
        let model = try makeModel(db, store: store)
        let a = rowA(model)
        let next = cell(model, "NextA")
        try store.save(MyListToggle.entry(channelKey: ChannelImporter.keyOf(a.channel),
                                          title: "NextA", description: nil,
                                          startMs: next.program!.startMs, endMs: next.program!.endMs,
                                          addedAtMs: 500))
        model.load()
        #expect(model.isSaved(channel: a.channel, cell: next))
    }

    @Test func firstCellMenuTargetIsAnInfoCell() throws {
        let db = try AppDatabase.makeInMemory()
        let model = try makeModel(db, store: MyListStore(db: db))
        let hit = try #require(model.firstCellMenuTarget())
        // The found cell must itself resolve to an info-cell menu (the affordance's gate).
        #expect(model.cellMenuTarget(for: hit.cell, row: rowA(model)) != nil)
    }

    @Test func ensureSavedIsIdempotent() throws {
        let db = try AppDatabase.makeInMemory()
        let store = MyListStore(db: db)
        let model = try makeModel(db, store: store)
        let hit = try #require(model.firstCellMenuTarget())
        model.ensureSaved(hit)
        model.ensureSaved(hit)
        #expect(model.isSaved(channel: hit.channel, cell: hit.cell))
        #expect(try store.all().count == 1)
    }

    @Test func nilStoreIsNoOp() throws {
        let db = try AppDatabase.makeInMemory()
        let model = try makeModel(db, store: MyListStore(db: db))
        model.myListStore = nil
        let a = rowA(model)
        let next = cell(model, "NextA")
        model.refreshMyListKeys()
        model.toggleMyList(channel: a.channel, cell: next)
        #expect(model.myListKeys.isEmpty)
        #expect(!model.isSaved(channel: a.channel, cell: next))
    }
}
