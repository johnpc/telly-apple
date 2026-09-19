import Testing
@testable import Telly

/// The multi-engine multiview session over ``FakePlayerEngine``: index-aligned
/// loads, the one-audible-tile mute policy across start/setActive/moveActive, and
/// full stop+release teardown. The engine-free DEBUG session is covered too.
@MainActor
struct MultiviewSessionTests {
    private func ch(_ id: Int) -> ChannelEntity {
        ChannelEntity(id: id, playlistId: 1, number: id, sortIndex: id,
                      source: ChannelSource(name: "Ch\(id)", groupTitle: "Live",
                                            streamUrl: "http://127.0.0.1/\(id).ts"))
    }
    private var channels: [ChannelEntity] { [ch(10), ch(20), ch(30), ch(40)] }

    private func makeSession(activeChannelId: Int? = 10)
        -> (MultiviewSession, [FakePlayerEngine]) {
        var engines: [FakePlayerEngine] = []
        let grid = MultiviewGrid(channels: channels, capacity: 4,
                                 activeChannelId: activeChannelId)!
        let session = MultiviewSession(grid: grid, makeEngine: {
            let engine = FakePlayerEngine(); engines.append(engine); return engine
        })
        return (session, engines)
    }

    @Test func startLoadsEachUrlOnceIndexAligned() {
        let (session, engines) = makeSession()
        session.start()
        #expect(engines.count == 4)
        #expect(engines[0].loaded == ["http://127.0.0.1/10.ts"])
        #expect(engines[3].loaded == ["http://127.0.0.1/40.ts"])
    }

    @Test func startLeavesOnlyActiveUnmuted() {
        let (session, engines) = makeSession(activeChannelId: 20)   // index 1
        session.start()
        #expect(engines.map(\.muted) == [true, false, true, true])
    }

    @Test func setActiveReMutes() {
        let (session, engines) = makeSession(activeChannelId: 10)
        session.start()
        session.setActive(2)
        #expect(session.grid.activeIndex == 2)
        #expect(engines.map(\.muted) == [true, true, false, true])
    }

    @Test func moveActiveUpdatesIndexAndAudio() {
        let (session, engines) = makeSession(activeChannelId: 10)   // index 0
        session.start()
        session.moveActive(.right)                                  // 0 → 1
        #expect(session.grid.activeIndex == 1)
        #expect(engines.map(\.muted) == [true, false, true, true])
    }

    @Test func closeStopsAndReleasesEveryEngine() {
        let (session, engines) = makeSession()
        session.close()
        #expect(engines.count == 4)
        #expect(engines.allSatisfy { $0.stopCount == 1 && $0.releaseCount == 1 })
    }

    @Test func startSkipsCellsThatCannotLoad() {
        var engines: [FakePlayerEngine] = []
        let grid = MultiviewGrid(channels: channels, capacity: 4, activeChannelId: 10)!
        let session = MultiviewSession(grid: grid, makeEngine: {
            let engine = FakePlayerEngine(); engines.append(engine); return engine
        }, canLoad: { $0.id != 30 })                      // ch30 (index 2) is gated
        session.start()
        #expect(engines[0].loaded == ["http://127.0.0.1/10.ts"])
        #expect(engines[2].loaded.isEmpty)                // gated tile never decodes
        #expect(engines[3].loaded == ["http://127.0.0.1/40.ts"])
        #expect(engines.map(\.muted) == [false, true, true, true])   // mute policy intact
    }

    @Test func engineAtReturnsNilOutOfRange() {
        let (session, _) = makeSession()
        #expect(session.engine(at: 9) == nil)
    }

    @Test func engineFreeSessionRendersFakeTiles() {
        let grid = MultiviewGrid(channels: channels, capacity: 4, activeChannelId: 10)!
        let session = MultiviewSession(grid: grid)
        #expect(session.engines.isEmpty)
        #expect(session.engine(at: 0) == nil)
        session.start()                                             // no-op, no crash
        session.moveActive(.right)                                  // focus still moves
        #expect(session.grid.activeIndex == 1)
    }
}
