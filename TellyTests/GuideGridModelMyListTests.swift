import Testing
import CoreGraphics
import Foundation
import GRDB
@testable import Telly

/// The guide cell's My List entry point (`GuideGridModel+MyList`/`+Info` + the
/// pure `GuideCellActions`): the info panel opens for any info-carrying cell and
/// offers the per-selection action (a future cell → My List); toggling snapshots
/// that programme into the shared `my_list` store and flips `isSaved`/`myListKeys`;
/// a nil store is a no-op; `load()` reflects a pre-seeded store. Real in-memory
/// GRDB is the backend.
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

    @Test func actionsOfferMyListForFutureCells() throws {
        let db = try AppDatabase.makeInMemory()
        let model = try makeModel(db, store: MyListStore(db: db))
        let a = rowA(model)
        // Future cell → My List; airing cell → Watch; filler → nothing.
        #expect(GuideCellActions.actions(for: model.selectCell(cell(model, "NextA"), row: a))
            == [.myList])
        #expect(GuideCellActions.actions(for: model.selectCell(cell(model, "NowA"), row: a))
            == [.watch])
        let filler = model.rows.first { $0.channel.epgId == "c" }!.cells.first!
        let cRow = model.rows.first { $0.channel.epgId == "c" }!
        #expect(GuideCellActions.actions(for: model.selectCell(filler, row: cRow)).isEmpty)
    }

    @Test func infoTargetForInfoCarryingCells() throws {
        let db = try AppDatabase.makeInMemory()
        let model = try makeModel(db, store: MyListStore(db: db))
        let a = rowA(model)
        // Future and airing cells both open the panel; a filler slot does not.
        #expect(model.infoTarget(for: cell(model, "NextA"), row: a)?.selection
            == .info(cell(model, "NextA")))
        #expect(model.infoTarget(for: cell(model, "NowA"), row: a)?.selection
            == .tune(a.channel))
        let cRow = model.rows.first { $0.channel.epgId == "c" }!
        #expect(model.infoTarget(for: cRow.cells.first!, row: cRow) == nil)
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

    @Test func firstInfoTargetIsAMyListCell() throws {
        let db = try AppDatabase.makeInMemory()
        let model = try makeModel(db, store: MyListStore(db: db))
        let hit = try #require(model.firstInfoTarget())
        // The screenshot seed's cell must offer My List (the flippable proof row).
        #expect(GuideCellActions.actions(for: hit.selection) == [.myList])
    }

    @Test func ensureSavedIsIdempotent() throws {
        let db = try AppDatabase.makeInMemory()
        let store = MyListStore(db: db)
        let model = try makeModel(db, store: store)
        let hit = try #require(model.firstInfoTarget())
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
