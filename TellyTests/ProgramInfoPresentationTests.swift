import Foundation
import Testing
@testable import Telly

/// The pure info-panel presentation: title/subtitle/episode, air-time range,
/// timing badge, genre chips, and the description-or-empty decision — with
/// missing / blank metadata gracefully omitted.
struct ProgramInfoPresentationTests {
    private let utc = TimeZone(identifier: "UTC")!

    private func program(_ details: ProgramDetails, start: Int, end: Int) -> ProgramEntity {
        ProgramEntity(channelTvgId: "a", startMs: start, endMs: end, details: details)
    }

    @Test func fullMetadataRenders() {
        let details = ProgramDetails(title: "Show", subTitle: "Pilot",
                                     description: "A synopsis.", category: "Drama, Crime",
                                     episode: "S1 E1")
        // 09:05–10:00 UTC on day 0, clock 09:10 → airing.
        let info = ProgramInfoPresentation.make(
            program: program(details, start: 32_700_000, end: 36_000_000),
            nowMs: 33_000_000, timeZone: utc)
        #expect(info.title == "Show")
        #expect(info.subtitle == "Pilot")
        #expect(info.episode == "S1 E1")
        #expect(info.timeRange == "09:05 — 10:00")
        #expect(info.timing == .now)
        #expect(info.categories == ["Drama", "Crime"])
        #expect(info.description == "A synopsis.")
        #expect(info.hasDescription)
    }

    @Test func missingSubtitleAndEpisodeAreNil() {
        let details = ProgramDetails(title: "Show", subTitle: nil, description: "d",
                                     category: nil, episode: "  ")
        let info = ProgramInfoPresentation.make(
            program: program(details, start: 0, end: 100), nowMs: 50, timeZone: utc)
        #expect(info.subtitle == nil)
        #expect(info.episode == nil)
        #expect(info.categories.isEmpty)
    }

    @Test func blankDescriptionBecomesEmptyState() {
        let details = ProgramDetails(title: "Show", description: "   \n ")
        let info = ProgramInfoPresentation.make(
            program: program(details, start: 0, end: 100), nowMs: 50, timeZone: utc)
        #expect(info.description == nil)
        #expect(!info.hasDescription)
    }

    @Test func futureProgrammeOnAnotherDayGetsDatePrefix() {
        let details = ProgramDetails(title: "Show")
        // Programme on day 1 while the clock is on day 0 → date-prefixed range.
        let info = ProgramInfoPresentation.make(
            program: program(details, start: 90_000_000, end: 93_600_000),
            nowMs: 1_000, timeZone: utc)
        #expect(info.timing == .upcoming)
        #expect(info.timeRange.hasPrefix("Fri, Jan 2"))
    }

    @Test func timingOverrideWins() {
        let details = ProgramDetails(title: "Show")
        let info = ProgramInfoPresentation.make(
            program: program(details, start: 90_000_000, end: 93_600_000),
            nowMs: 1_000, timeZone: utc, timingOverride: .next)
        #expect(info.timing == .next)
    }
}
