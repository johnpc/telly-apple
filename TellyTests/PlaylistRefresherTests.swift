import Testing
@testable import Telly

/// Unit coverage for the pure per-playlist auto-refresh policy. The playlist
/// lookup, per-URL settings, updater and clock are all injected, so no wall
/// clock or I/O is touched (RefreshSchedulerTests precedent).
struct PlaylistRefresherTests {
    private static let urlA = "http://127.0.0.1:8000/a/playlist.m3u"
    private static let urlB = "http://127.0.0.1:8000/b/playlist.m3u"

    private func playlist(_ url: String, lastUpdatedMs: Int64) -> PlaylistEntity {
        PlaylistEntity(id: nil, name: "n", url: url, epgUrl: nil, lastUpdatedMs: lastUpdatedMs)
    }

    private func refresher(
        _ playlists: [PlaylistEntity],
        interval: @escaping (String) -> Int = { _ in 0 },
        onStart: @escaping (String) -> Bool = { _ in false },
        now: Int
    ) -> PlaylistRefresher {
        PlaylistRefresher(
            playlists: { playlists },
            update: { _ in true },
            intervalHours: interval,
            updateOnStart: onStart,
            clock: { now })
    }

    @Test func intervalZeroNeverDue() async {
        let now = 10 * RefreshScheduler.dayMs
        let r = refresher([playlist(Self.urlA, lastUpdatedMs: 1)], interval: { _ in 0 }, now: now)
        #expect(await r.refreshDue().isEmpty)
    }

    @Test func agedPastIntervalIsRefreshed() async {
        let now = 10 * RefreshScheduler.dayMs
        let stamp = Int64(now - 2 * RefreshScheduler.hourMs)
        let r = refresher([playlist(Self.urlA, lastUpdatedMs: stamp)], interval: { _ in 1 }, now: now)
        #expect(await r.refreshDue() == [Self.urlA])
    }

    @Test func withinIntervalNotDue() async {
        let now = 10 * RefreshScheduler.dayMs
        let r = refresher([playlist(Self.urlA, lastUpdatedMs: Int64(now - 1))],
                          interval: { _ in 24 }, now: now)
        #expect(await r.refreshDue().isEmpty)
    }

    @Test func updateOnStartForcesNotYetDue() async {
        let now = 10 * RefreshScheduler.dayMs
        // Freshly stamped: not due by interval, but on-start forces a refresh.
        let r = refresher([playlist(Self.urlA, lastUpdatedMs: Int64(now - 1))],
                          interval: { _ in 24 }, onStart: { $0 == Self.urlA }, now: now)
        #expect(await r.refreshOnStart() == [Self.urlA])
        #expect(await r.refreshDue().isEmpty)
    }

    @Test func throwingLookupYieldsEmpty() async {
        struct Boom: Error {}
        let r = PlaylistRefresher(
            playlists: { throw Boom() },
            update: { _ in true },
            intervalHours: { _ in 1 },
            updateOnStart: { _ in true },
            clock: { 10 * RefreshScheduler.dayMs })
        #expect(await r.refreshOnStart().isEmpty)
    }

    @Test func onlySuccessfulUrlsReturned() async {
        let now = 10 * RefreshScheduler.dayMs
        let stamp = Int64(now - 2 * RefreshScheduler.hourMs)
        let items = [playlist(Self.urlA, lastUpdatedMs: stamp), playlist(Self.urlB, lastUpdatedMs: stamp)]
        let r = PlaylistRefresher(
            playlists: { items },
            update: { $0 == Self.urlA },
            intervalHours: { _ in 1 },
            updateOnStart: { _ in false },
            clock: { now })
        #expect(await r.refreshDue() == [Self.urlA])
    }
}
