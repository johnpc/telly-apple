import Foundation
import Testing
@testable import Telly

/// The pure search-results builder: channel cards keep input order + carry
/// now/progress from the guide map keyed by epgId; the Programs section groups
/// matches one-per-channel (first visible channel per tvg-id wins, unknown ids
/// drop), airings chronological and never merged, channels ordered by name then
/// number, with airing-vs-upcoming progress/remaining. UTC keeps it deterministic.
struct SearchResultsBuilderTests {
    private let utc = TimeZone(identifier: "UTC")!

    private func ch(_ id: Int, name: String, number: Int, tvgId: String?) -> ChannelEntity {
        ChannelEntity(id: id, playlistId: 1, number: number, sortIndex: number,
                      source: ChannelSource(name: name, groupTitle: "Live",
                                            streamUrl: "http://127.0.0.1/\(id).ts", tvgId: tvgId))
    }

    private func prog(_ tvgId: String, _ startMs: Int, _ endMs: Int, _ title: String) -> ProgramEntity {
        ProgramEntity(channelTvgId: tvgId, startMs: startMs, endMs: endMs,
                      details: ProgramDetails(title: title))
    }

    // MARK: channels()

    @Test func channelsKeepInputOrderAndAttachNow() {
        let a = ch(1, name: "Beta", number: 9, tvgId: "b")
        let b = ch(2, name: "Alpha", number: 1, tvgId: "a")
        let now = prog("b", 0, 100, "Now B")
        let guide = ["b": NowNext(now: now, next: nil)]
        let hits = SearchResultsBuilder.channels(matches: [a, b], nowNext: guide, atMs: 50, timeZone: utc)
        #expect(hits.map { $0.channel.id } == [1, 2]) // input order preserved (no re-sort)
        #expect(hits[0].nowTitle == "Now B")
        #expect(hits[0].progress == 0.5)
    }

    @Test func channelsNilWhenNoNowProgramme() {
        let a = ch(1, name: "Alpha", number: 1, tvgId: "a")
        let hits = SearchResultsBuilder.channels(matches: [a], nowNext: [:], atMs: 50, timeZone: utc)
        #expect(hits[0].nowTitle == nil)
        #expect(hits[0].progress == nil)
    }

    // MARK: programs() grouping

    @Test func programsGroupOnePerChannelDropUnknown() {
        let a = ch(1, name: "Alpha", number: 1, tvgId: "a")
        let matches = [prog("a", 0, 100, "Show"), prog("ghost", 0, 100, "Orphan")]
        let groups = SearchResultsBuilder.programs(matches: matches, channels: [a], atMs: 50, timeZone: utc)
        #expect(groups.count == 1)
        #expect(groups[0].channel.id == 1)
        #expect(groups[0].airings.count == 1) // orphan tvg-id dropped
    }

    @Test func firstVisibleChannelPerTvgIdWins() {
        let first = ch(1, name: "First", number: 1, tvgId: "dup")
        let second = ch(2, name: "Second", number: 2, tvgId: "dup")
        let groups = SearchResultsBuilder.programs(matches: [prog("dup", 0, 100, "Show")],
                                                   channels: [first, second], atMs: 50, timeZone: utc)
        #expect(groups.count == 1)
        #expect(groups[0].channel.id == 1) // first occurrence wins
    }

    @Test func airingsSortedByStartAndNeverMerged() {
        let a = ch(1, name: "Alpha", number: 1, tvgId: "a")
        let matches = [prog("a", 300, 400, "Same"), prog("a", 100, 200, "Same")]
        let groups = SearchResultsBuilder.programs(matches: matches, channels: [a], atMs: 0, timeZone: utc)
        #expect(groups[0].airings.count == 2) // two airings → two rows, never merged
        #expect(groups[0].airings.map { $0.program.startMs } == [100, 300]) // chronological
    }

    @Test func channelsOrderedByNameThenNumber() {
        let beta = ch(1, name: "beta", number: 5, tvgId: "b")
        let alphaHi = ch(2, name: "Alpha", number: 9, tvgId: "a1")
        let alphaLo = ch(3, name: "Alpha", number: 2, tvgId: "a2")
        let matches = [prog("b", 0, 100, "x"), prog("a1", 0, 100, "x"), prog("a2", 0, 100, "x")]
        let groups = SearchResultsBuilder.programs(matches: matches,
                                                   channels: [beta, alphaHi, alphaLo], atMs: 50, timeZone: utc)
        // case-insensitive name: both Alpha before beta; ties by number (2 before 9).
        #expect(groups.map { $0.channel.id } == [3, 2, 1])
    }

    // MARK: airing vs upcoming

    @Test func airingRowHasProgressAndRemaining() {
        let a = ch(1, name: "Alpha", number: 1, tvgId: "a")
        // airing: start 0, end 600_000 (10 min), now at 300_000 (5 min in) → 5 min left.
        let groups = SearchResultsBuilder.programs(matches: [prog("a", 0, 600_000, "Live")],
                                                   channels: [a], atMs: 300_000, timeZone: utc)
        #expect(groups[0].airings[0].progress == 0.5)
        #expect(groups[0].airings[0].remaining == "5 min")
    }

    @Test func upcomingRowHasNilProgressAndRemaining() {
        let a = ch(1, name: "Alpha", number: 1, tvgId: "a")
        let groups = SearchResultsBuilder.programs(matches: [prog("a", 600_000, 900_000, "Later")],
                                                   channels: [a], atMs: 300_000, timeZone: utc)
        #expect(groups[0].airings[0].progress == nil)
        #expect(groups[0].airings[0].remaining == nil)
    }

    @Test func remainingRoundsUp() {
        let a = ch(1, name: "Alpha", number: 1, tvgId: "a")
        // 90 seconds left → ceil to 2 min.
        let groups = SearchResultsBuilder.programs(matches: [prog("a", 0, 90_000, "Live")],
                                                   channels: [a], atMs: 0, timeZone: utc)
        #expect(groups[0].airings[0].remaining == "2 min")
    }

    // MARK: SearchResults value

    @Test func emptyResultsAreEmpty() {
        #expect(SearchResults().isEmpty)
        #expect(SearchResults(query: "q").isEmpty)
    }

    @Test func nonEmptyResultsAreNotEmpty() {
        let a = ch(1, name: "Alpha", number: 1, tvgId: "a")
        let hit = SearchProgramHit(program: prog("a", 0, 100, "x"), channel: a, title: "x",
                                   timeText: "t", progress: nil, remaining: nil)
        let results = SearchResults(query: "q", channels: [],
                                    programs: [SearchProgramChannel(channel: a, airings: [hit])])
        #expect(!results.isEmpty)
    }
}
