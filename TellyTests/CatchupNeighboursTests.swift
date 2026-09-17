import Testing
@testable import Telly

/// Unit coverage for `CatchupNeighbours` — the ported previous/next boundary
/// logic, the still-airing/off-edge `.live` fallbacks, and the catchup-days
/// horizon filter (reusing the real `CatchupPlayability`). Pure: `programs`/
/// `clock` are injected, so no DB or VLCKit is touched.
struct CatchupNeighboursTests {
    private let now = 10_000_000_000
    private let dayMs = 24 * 3_600_000
    private let hourMs = 3_600_000

    private func channel(days: Int = 7, tvgId: String? = "news.tv") -> ChannelEntity {
        ChannelEntity(
            playlistId: 1, number: 1, sortIndex: 0,
            source: ChannelSource(name: "News", groupTitle: nil, logoUrl: nil,
                                  streamUrl: "http://127.0.0.1/live/news.ts", tvgId: tvgId),
            catchup: ChannelCatchup(catchupType: "default",
                                    catchupSource: "http://127.0.0.1/a?utc=${start}&dur=${duration}",
                                    catchupDays: days))
    }

    private func program(_ start: Int, _ end: Int, _ title: String) -> ProgramEntity {
        ProgramEntity(channelTvgId: "news.tv", startMs: start, endMs: end,
                      details: ProgramDetails(title: title))
    }

    private func request(_ chan: ChannelEntity, start: Int, end: Int) -> CatchupRequest {
        CatchupRequest(channel: chan, url: "http://127.0.0.1/req", title: "R", startMs: start, endMs: end)
    }

    private func neighbours(_ programs: [ProgramEntity]) -> CatchupNeighbours {
        CatchupNeighbours(programs: { _, _, _ in programs }, clock: { self.now })
    }

    @Test func previousPicksNewestFullyEndedNeighbour() {
        let chan = channel()
        let req = request(chan, start: now - 20 * hourMs, end: now - 18 * hourMs)
        let n = neighbours([
            program(now - 24 * hourMs, now - 20 * hourMs, "Prev A"),
            program(now - 28 * hourMs, now - 24 * hourMs, "Prev B"),
        ])
        let prev = n.previous(req)
        #expect(prev?.title == "Prev A")
        #expect(prev?.startMs == now - 24 * hourMs)
    }

    @Test func previousNilWhenNoEndedNeighbour() {
        let chan = channel()
        let req = request(chan, start: now - 20 * hourMs, end: now - 18 * hourMs)
        // Only a programme ending AFTER the request start (not a "previous").
        let n = neighbours([program(now - 21 * hourMs, now - 19 * hourMs, "Overlap")])
        #expect(n.previous(req) == nil)
    }

    @Test func nextPicksOldestUpcomingArchive() {
        let chan = channel()
        let req = request(chan, start: now - 20 * hourMs, end: now - 18 * hourMs)
        let n = neighbours([
            program(now - 18 * hourMs, now - 16 * hourMs, "Next C"),
            program(now - 16 * hourMs, now - 14 * hourMs, "Next D"),
        ])
        guard case let .archive(req2) = n.next(req) else { Issue.record("expected archive"); return }
        #expect(req2.title == "Next C")
        #expect(req2.startMs == now - 18 * hourMs)
    }

    @Test func nextLiveWhenNeighbourStillAiring() {
        let chan = channel()
        let req = request(chan, start: now - 3 * hourMs, end: now - 2 * hourMs)
        // Oldest upcoming is still airing (endMs > now) → back to live.
        let n = neighbours([program(now - 2 * hourMs, now + hourMs, "Airing")])
        #expect(n.next(req) == .live)
    }

    @Test func nextLiveWhenNoneInWindow() {
        let chan = channel()
        let req = request(chan, start: now - 3 * hourMs, end: now - 2 * hourMs)
        #expect(neighbours([]).next(req) == .live)
    }

    @Test func previousNilWhenNeighbourOutsideHorizon() {
        let chan = channel(days: 7)
        let req = request(chan, start: now - hourMs, end: now)
        // Ended, but its start predates the 7-day horizon → not playable.
        let n = neighbours([program(now - 8 * dayMs, now - 8 * dayMs + hourMs, "Ancient")])
        #expect(n.previous(req) == nil)
    }

    @Test func nextLiveWhenNeighbourOutsideHorizon() {
        let chan = channel(days: 7)
        let start = now - 9 * dayMs
        let req = request(chan, start: start, end: start + hourMs)
        // Ended and upcoming relative to the request, but pre-horizon → .live.
        let n = neighbours([program(start + hourMs, start + 2 * hourMs, "Ancient Next")])
        #expect(n.next(req) == .live)
    }

    @Test func emptyWhenChannelHasNoEpgId() {
        let chan = channel(tvgId: nil)
        let req = request(chan, start: now - 20 * hourMs, end: now - 18 * hourMs)
        // With no epgId the window lookup is skipped entirely.
        let n = CatchupNeighbours(
            programs: { _, _, _ in [self.program(self.now - 24 * self.hourMs, self.now - 20 * self.hourMs, "X")] },
            clock: { self.now })
        #expect(n.previous(req) == nil)
        #expect(n.next(req) == .live)
    }
}
