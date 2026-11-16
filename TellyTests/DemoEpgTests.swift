import Testing
import Foundation
@testable import Telly

/// The generated demo guide: every live demo channel gets a gapless, back-to-back
/// schedule spanning the past-6h…+24h window around the clock it is given, with a
/// programme airing "now" so the info overlay / guide now-line always have data.
struct DemoEpgTests {
    private let utc = TimeZone(identifier: "UTC")!
    private let nowMs = 1_760_000_000_000  // 2025-10-09T08:53:20Z

    @Test func everyLiveChannelIsScheduledAcrossTheWindow() {
        let doc = DemoEpg.document(nowMs: nowMs, timeZone: utc)
        let ids = Set(doc.programs.map(\.channelId))
        #expect(ids == Set(DemoContent.liveChannels.compactMap(\.tvgID)))
        let origin = GuideGeometry.halfHourFloor(nowMs, timeZone: utc) - DemoEpg.pastHours * 3_600_000
        let end = origin + (DemoEpg.pastHours + DemoEpg.futureHours) * 3_600_000
        for id in ids {
            let rows = doc.programs.filter { $0.channelId == id }
            #expect(rows.first?.startMs == origin)
            #expect(rows.last?.endMs == end)
            for (prev, next) in zip(rows, rows.dropFirst()) { #expect(prev.endMs == next.startMs) }
        }
    }

    @Test func somethingIsAiringNowOnEveryChannelWithWording() {
        let doc = DemoEpg.document(nowMs: nowMs, timeZone: utc)
        for id in DemoContent.liveChannels.compactMap(\.tvgID) {
            let airing = doc.programs.first { $0.channelId == id && $0.startMs <= nowMs && nowMs < $0.endMs }
            #expect(airing != nil, "no programme airing on \(id)")
            #expect(airing?.details.description?.isEmpty == false)
            #expect(airing?.details.category?.isEmpty == false)
        }
    }

    @Test func scheduleIsDeterministicForTheSameClock() {
        #expect(DemoEpg.document(nowMs: nowMs, timeZone: utc) == DemoEpg.document(nowMs: nowMs, timeZone: utc))
    }

    @Test func downloaderServesTheDemoGuideInProcess() async throws {
        var downloader = EpgDownloader { _ in Issue.record("network must not be touched"); return Data() }
        downloader.now = { nowMs }
        let doc = try await downloader.download(epgUrl: DemoContent.epgUrl)
        #expect(doc == DemoEpg.document(nowMs: nowMs))
    }
}

/// The wording table: every demo group has a category and eight titles; an
/// unknown group falls back to the last (Music) row rather than crashing.
struct DemoProgramWordingTests {
    @Test func everyGroupHasCategoryAndEightTitles() {
        for group in ["News", "Sports", "Movies", "Kids", "Music"] {
            let wording = DemoProgramWording.forGroup(group)
            #expect(!wording.category.isEmpty)
            #expect(wording.titles.count == 8, "group \(group)")
        }
        #expect(DemoProgramWording.forGroup("Movies").category == "Movie / Drama")
    }

    @Test func unknownGroupFallsBackToTheLastRow() {
        #expect(DemoProgramWording.forGroup("Nope") == DemoProgramWording.forGroup("Music"))
    }
}
