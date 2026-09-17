import Foundation
import Testing
@testable import Telly

/// Unit coverage for the info-overlay pure formatting + empty-state decisions.
struct InfoOverlayTextTests {
    private let utc = TimeZone(identifier: "UTC")!

    private func program(_ start: Int, _ end: Int, _ title: String) -> ProgramEntity {
        ProgramEntity(channelTvgId: "a", startMs: start, endMs: end,
                      details: ProgramDetails(title: title))
    }

    @Test func clockZeroPadsHourAndMinute() {
        // 09:05 UTC = (9*3600 + 5*60) * 1000 ms.
        #expect(InfoOverlayText.clock(nowMs: 32_700_000, timeZone: utc) == "09:05")
    }

    @Test func timeLabelFormatsProgramBoundary() {
        // 23:59 UTC.
        #expect(InfoOverlayText.timeLabel(86_340_000, timeZone: utc) == "23:59")
    }

    @Test func hasProgramFalseWhenNil() {
        #expect(InfoOverlayText.hasProgram(nil) == false)
    }

    @Test func hasProgramFalseWhenNowAbsent() {
        #expect(InfoOverlayText.hasProgram(NowNext(now: nil, next: program(0, 100, "x"))) == false)
    }

    @Test func hasProgramTrueWhenNowPresent() {
        #expect(InfoOverlayText.hasProgram(NowNext(now: program(0, 100, "x"), next: nil)) == true)
    }

    @Test func nowTitleReadsDetailsTitle() {
        #expect(InfoOverlayText.nowTitle(NowNext(now: program(0, 100, "Now"), next: nil)) == "Now")
    }

    @Test func nowTitleNilWhenAbsent() {
        #expect(InfoOverlayText.nowTitle(nil) == nil)
    }

    @Test func nextTitleReadsDetailsTitle() {
        #expect(InfoOverlayText.nextTitle(NowNext(now: nil, next: program(0, 100, "Next"))) == "Next")
    }

    @Test func nextTitleNilWhenNextAbsent() {
        #expect(InfoOverlayText.nextTitle(NowNext(now: program(0, 100, "Now"), next: nil)) == nil)
    }
}
