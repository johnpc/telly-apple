import Testing
import CoreGraphics
import Foundation
import GRDB
@testable import Telly

/// The guide grid model's tvOS focus navigation: horizontal stepping with edge
/// panning, the never-pan-left-of-now hold, and vertical row moves that keep the
/// time anchor. Uses a one-cell viewport so a single RIGHT step pans the scroll.
@MainActor
struct GuideGridModelFocusTests {
    static let originMs = 3_600_000

    private func m(_ name: String) -> M3uChannel {
        M3uChannel(title: name, streamURL: "http://x/\(name)", tvgID: name, tvgName: nil,
                   tvgLogo: nil, groupTitle: "G", catchup: nil, catchupSource: nil, catchupDays: nil)
    }

    private func prog(_ ch: String, _ start: Int, _ end: Int, _ title: String) -> XmltvProgram {
        XmltvProgram(channelId: ch, startMs: start, endMs: end,
                     details: ProgramDetails(title: title, subTitle: nil, description: nil,
                                             category: nil, episode: nil))
    }

    /// Two channels a/b with back-to-back cells around the origin; a one-cell
    /// (160-pt) viewport so a right step past the origin cell forces a pan.
    private func makeModel() throws -> GuideGridModel {
        let o = Self.originMs
        let db = try AppDatabase.makeInMemory()
        _ = try PlaylistStore(db: db).add(
            sourceUrl: "u", playlist: M3uPlaylist(channels: [m("a"), m("b")]), name: nil, nowMs: 0)
        try ProgramStore(db: db).upsertReplacing(document: XmltvDocument(channels: [], programs: [
            prog("a", o - 1_800_000, o, "PrevA"), prog("a", o, o + 1_800_000, "NowA"),
            prog("a", o + 1_800_000, o + 3_600_000, "NextA"),
            prog("b", o, o + 1_800_000, "NowB")]), keepDescriptions: true)
        let model = GuideGridModel(
            channelStore: ChannelStore(db: db),
            repository: EpgRepository(store: ProgramStore(db: db)), now: { o },
            timeZone: TimeZone(identifier: "UTC")!, is24h: true, viewport: 160)
        model.load()
        return model
    }

    @Test func focusRightStepsAndPansAtRightEdge() throws {
        let model = try makeModel()
        #expect(model.focus?.cell.program?.details.title == "NowA")
        #expect(model.scrollX == 0)
        model.focusRight()
        #expect(model.focus?.cell.program?.details.title == "NextA")
        #expect(model.scrollX > 0)
    }

    @Test func focusLeftHoldsAtNowEdge() throws {
        let model = try makeModel()
        let before = model.focus
        model.focusLeft()
        #expect(model.focus == before)
    }

    @Test func focusLeftReturnsAfterStepRight() throws {
        let model = try makeModel()
        model.focusRight()
        model.focusLeft()
        #expect(model.focus?.cell.program?.details.title == "NowA")
    }

    @Test func focusDownAndUpKeepTheTimeAnchor() throws {
        let model = try makeModel()
        let anchor = model.focus!.anchorMs
        model.focusDown()
        #expect(model.focus?.rowIndex == 1)
        #expect(model.focus?.anchorMs == anchor)
        #expect(model.focus?.cell.program?.details.title == "NowB")
        model.focusUp()
        #expect(model.focus?.rowIndex == 0)
    }
}
