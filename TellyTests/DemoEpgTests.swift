import Testing
import Foundation
@testable import Telly

/// The generated demo guide: every live demo channel gets a gapless, back-to-back
/// schedule spanning yesterday 00:00 … tomorrow 24:00 (local) around the clock it
/// is given, with a programme airing "now" so the info overlay / guide now-line
/// always have data, and the same programme grid on every day.
struct DemoEpgTests {
    private let utc = TimeZone(identifier: "UTC")!
    private let nowMs = 1_760_000_000_000  // 2025-10-09T08:53:20Z

    @Test func everyLiveChannelIsScheduledAcrossTheWindow() {
        let doc = DemoEpg.document(nowMs: nowMs, timeZone: utc)
        let ids = Set(doc.programs.map(\.channelId))
        #expect(ids == Set(DemoContent.liveChannels.compactMap(\.tvgID)))
        let span = DemoEpg.window(nowMs: nowMs, timeZone: utc)
        #expect(span.lowerBound == 1_759_881_600_000)   // 2025-10-08T00:00:00Z (yesterday)
        #expect(span.upperBound == 1_760_140_800_000)   // 2025-10-11T00:00:00Z (end of tomorrow)
        for id in ids {
            let rows = doc.programs.filter { $0.channelId == id }
            #expect(rows.first?.startMs == span.lowerBound)
            #expect(rows.last?.endMs == span.upperBound)
            for (prev, next) in zip(rows, rows.dropFirst()) { #expect(prev.endMs == next.startMs) }
        }
    }

    /// Every day starts on the same programme grid (the 6-hour pattern divides a
    /// day), and the first channel opens each day with a 30-minute programme — so
    /// a compact iPhone pane at a day's start shows two cells, deterministically.
    @Test func everyDayStartsOnTheSameGridRegardlessOfClock() {
        for clock in [nowMs, nowMs + 13 * 3_600_000, nowMs + 50 * 3_600_000] {
            let doc = DemoEpg.document(nowMs: clock, timeZone: utc)
            let span = DemoEpg.window(nowMs: clock, timeZone: utc)
            let first = DemoContent.liveChannels[0].tvgID
            for midnight in stride(from: span.lowerBound, to: span.upperBound, by: 86_400_000) {
                for id in DemoContent.liveChannels.compactMap(\.tvgID) {
                    #expect(doc.programs.contains { $0.channelId == id && $0.startMs == midnight }, "\(id) @\(midnight)")
                }
                let opener = doc.programs.first { $0.channelId == first && $0.startMs == midnight }
                #expect(opener.map { $0.endMs - $0.startMs } == 30 * 60_000)
            }
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
