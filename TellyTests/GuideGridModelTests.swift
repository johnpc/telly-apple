import Testing
import CoreGraphics
import Foundation
import GRDB
@testable import Telly

/// The observable guide grid model at a fixed UTC clock: row materialisation for
/// seeded channels + programmes, all-filler rows, the cell-activation rule,
/// scroll clamping/re-materialisation, and per-channel offset application.
@MainActor
struct GuideGridModelTests {
    static let originMs = 3_600_000  // on a 30-min boundary → its own half-hour floor

    private func m(_ name: String) -> M3uChannel {
        M3uChannel(title: name, streamURL: "http://x/\(name)", tvgID: name, tvgName: nil,
                   tvgLogo: nil, groupTitle: "G", catchup: nil, catchupSource: nil, catchupDays: nil)
    }

    private func prog(_ ch: String, _ start: Int, _ end: Int, _ title: String) -> XmltvProgram {
        XmltvProgram(channelId: ch, startMs: start, endMs: end,
                     details: ProgramDetails(title: title, subTitle: nil, description: nil,
                                             category: nil, episode: nil))
    }

    /// Seeds channels a/b/c: a carries Prev/Now/Next back-to-back around the
    /// origin, b carries a single future OnlyB (shifted by `offsetB` minutes), c
    /// is dataless. Returns a loaded model at a fixed UTC clock on the origin.
    func makeModel(offsetB: Int = 0, viewport: CGFloat = 960) throws -> GuideGridModel {
        let o = Self.originMs
        let db = try AppDatabase.makeInMemory()
        _ = try PlaylistStore(db: db).add(
            sourceUrl: "u", playlist: M3uPlaylist(channels: [m("a"), m("b"), m("c")]),
            name: nil, nowMs: 0)
        if offsetB != 0 {
            try db.queue.write {
                try $0.execute(sql: "UPDATE channels SET epgOffsetMinutes = ? WHERE tvgId = 'b'",
                               arguments: [offsetB])
            }
        }
        try ProgramStore(db: db).upsertReplacing(document: XmltvDocument(channels: [], programs: [
            prog("a", o - 1_800_000, o, "PrevA"), prog("a", o, o + 1_800_000, "NowA"),
            prog("a", o + 1_800_000, o + 3_600_000, "NextA"),
            prog("b", o + 1_800_000, o + 3_600_000, "OnlyB")]), keepDescriptions: true)
        let model = GuideGridModel(
            channelStore: ChannelStore(db: db),
            repository: EpgRepository(store: ProgramStore(db: db)), now: { o },
            timeZone: TimeZone(identifier: "UTC")!, is24h: true, viewport: viewport)
        model.load()
        return model
    }

    private func row(_ model: GuideGridModel, _ epgId: String) -> GuideRow {
        model.rows.first { $0.channel.epgId == epgId }!
    }

    @Test func loadBuildsRowsForSeededChannels() throws {
        let model = try makeModel()
        #expect(model.channels.count == 3)
        #expect(model.rows.count == 3)
        #expect(row(model, "a").cells.contains { $0.program?.details.title == "NowA" })
    }

    @Test func epgLessChannelIsAllFiller() throws {
        let model = try makeModel()
        let c = row(model, "c")
        #expect(!c.cells.isEmpty)
        #expect(c.cells.allSatisfy { !$0.hasInfo })
    }

    @Test func selectCellClassifiesTuneInfoAndNone() throws {
        let model = try makeModel()
        let a = row(model, "a")
        let nowCell = a.cells.first { $0.program?.details.title == "NowA" }!
        let future = a.cells.first { $0.program?.details.title == "NextA" }!
        let filler = row(model, "c").cells.first!
        #expect(model.selectCell(nowCell, row: a) == .tune(a.channel))
        #expect(model.selectCell(future, row: a) == .info(future))
        #expect(model.selectCell(filler, row: row(model, "c")) == GuideSelection.none)
    }

    @Test func scrollTimeClampsAtFloorAndCeilAndReMaterialises() throws {
        let model = try makeModel()
        model.scrollTime(byPoints: 5_000_000)
        #expect(model.scrollX == GuideWindowMath.scrollCeil())
        #expect(!model.rows.isEmpty)
        model.scrollTime(byPoints: -50_000_000)
        #expect(model.scrollX == GuideWindowMath.scrollFloor(pastDays: GuideGridModel.pastDays))
    }

    @Test func jumpToNowResetsScroll() throws {
        let model = try makeModel()
        model.scrollTime(byPoints: 640)
        #expect(model.scrollX != 0)
        model.jumpToNow()
        #expect(model.scrollX == 0)
    }

    @Test func timelineTicksSpanTheViewportFromTheOrigin() throws {
        let model = try makeModel()
        let ticks = model.timelineTicks
        #expect(!ticks.isEmpty)
        #expect(ticks.first?.offset == 0)  // origin sits at scrollX 0
        #expect(ticks.first?.label == "01:00")  // originMs 3_600_000 = 01:00 UTC, 24h
    }

    @Test func nowLineOffsetSitsAtTheOriginAndVanishesOffPane() throws {
        let model = try makeModel()
        #expect(model.nowLineOffset == 0)  // now == origin → left edge
        model.scrollTime(byPoints: GuideGeometry.pointsPer30Min)  // pan now off the left edge
        #expect(model.nowLineOffset == nil)
    }

    @Test func setViewportRematerializesAndClamps() throws {
        let model = try makeModel(viewport: 960)
        #expect(model.timelineTicks.count == 7)  // 960 / 160 = 6 columns → 7 marks
        model.setViewport(320)  // 2 columns
        #expect(model.viewport == 320)
        #expect(model.timelineTicks.count == 3)
        #expect(model.nowLineOffset == 0)  // now at origin stays on the narrower pane
        model.setViewport(1600)  // 10 columns
        #expect(model.timelineTicks.count == 11)
        model.setViewport(0)  // non-positive is ignored
        #expect(model.viewport == 1600)
        model.setViewport(1600)  // unchanged is ignored
        #expect(model.viewport == 1600)
    }

    @Test func perChannelOffsetShiftsPickedProgramme() throws {
        let shifted = try makeModel(offsetB: -30)
        let plain = try makeModel(offsetB: 0)
        #expect(row(shifted, "b").cells.first { $0.contains(Self.originMs) }?
            .program?.details.title == "OnlyB")
        #expect(row(plain, "b").cells.first { $0.contains(Self.originMs) }?.hasInfo == false)
    }
}
