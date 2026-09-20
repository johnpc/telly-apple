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

    @Test func engineAtReturnsNilOutOfRange() {
        let (session, _) = makeSession()
        #expect(session.engine(at: 9) == nil)
    }

    private func makeSession(count: Int)
        -> (MultiviewSession, [FakePlayerEngine]) {
        var engines: [FakePlayerEngine] = []
        let grid = MultiviewGrid(channels: Array(channels.prefix(count)), capacity: 4,
                                 activeChannelId: channels.first?.id)!
        let session = MultiviewSession(grid: grid, makeEngine: {
            let engine = FakePlayerEngine(); engines.append(engine); return engine
        })
        session.start()
        return (session, engines)
    }

    @Test func addPaneMintsLoadsMutedEngineIndexAligned() {
        let (session, _) = makeSession(count: 2)
        session.addPane(ch(30))
        // Read the session's live engine set (a returned array copy wouldn't see
        // the engine minted after makeSession returned — Swift arrays are values).
        let tiles = session.engines.compactMap { $0 as? FakePlayerEngine }
        #expect(session.grid.cells.map(\.id) == [10, 20, 30])
        #expect(tiles.count == 3)
        #expect(tiles[2].loaded == ["http://127.0.0.1/30.ts"])
        #expect(tiles.map(\.muted) == [false, true, true])
    }

    @Test func addPaneDuplicateMintsNoEngine() {
        let (session, _) = makeSession(count: 2)
        session.addPane(ch(10))                     // already shown → grid no-op
        #expect(session.grid.cells.count == 2)
        #expect(session.engines.count == 2)         // no engine minted
    }

    @Test func removePaneStopsReleasesAndDropsEngine() {
        let (session, engines) = makeSession(count: 3)
        session.removePane(at: 1)
        #expect(session.grid.cells.map(\.id) == [10, 30])
        #expect(engines[1].stopCount == 1 && engines[1].releaseCount == 1)
        #expect(session.engines.count == 2)
    }

    @Test func changeChannelReloadsThatPaneOnly() {
        let (session, engines) = makeSession(count: 2)
        session.changeChannel(at: 1, to: ch(40))
        #expect(session.grid.cells.map(\.id) == [10, 40])
        #expect(engines[1].loaded == ["http://127.0.0.1/20.ts", "http://127.0.0.1/40.ts"])
        #expect(engines[0].loaded == ["http://127.0.0.1/10.ts"])   // untouched
    }

    @Test func menuOpensMovesAndResolvesRow() {
        let (session, _) = makeSession(count: 2)
        session.openMenu()
        #expect(session.selectedMenuRow == .changeChannel)
        session.moveMenu(1)
        #expect(session.selectedMenuRow == .fullscreen)
        session.moveMenu(5)                         // clamps to last row
        #expect(session.menu?.selection == session.menuRows.count - 1)
        session.closeMenu()
        #expect(session.menu == nil)
    }

    @Test func pickerOpenReplacesMenuAndClampsMotion() {
        let (session, _) = makeSession(count: 2)
        session.openMenu()
        session.openPicker(.add)
        #expect(session.menu == nil)
        #expect(session.picker?.mode == .add)
        session.movePicker(2, count: 4)
        #expect(session.picker?.selection == 2)
        session.closePicker()
        #expect(session.picker == nil)
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
