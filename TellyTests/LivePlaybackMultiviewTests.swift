import Testing
@testable import Telly

/// The live orchestrator's multiview entry/menu/picker/promote/exit, composed
/// over the `makeEngine` tile factory and ``FakePlayerEngine`` so every load,
/// mute and teardown is asserted without VLCKit. Android model: enter with ONE
/// pane, add more from the pane menu; OK opens the pane menu (not fullscreen).
@MainActor
struct LivePlaybackMultiviewTests {
    @MainActor
    final class Harness {
        let engine = FakePlayerEngine()
        var tiles: [FakePlayerEngine] = []
        var clock = 0

        func makeModel(_ channels: [ChannelEntity]) -> LivePlaybackModel {
            LivePlaybackModel(
                engine: engine,
                channels: channels,
                makeEngine: { let e = FakePlayerEngine(); self.tiles.append(e); return e },
                now: { self.clock },
                persistLastChannel: { _ in },
                loadLastChannel: { nil },
                onExitToGuide: {})
        }
    }

    private func ch(_ id: Int, _ number: Int) -> ChannelEntity {
        ChannelEntity(id: id, playlistId: 1, number: number, sortIndex: number,
                      source: ChannelSource(name: "Ch\(id)", groupTitle: "Live",
                                            streamUrl: "http://127.0.0.1/\(id).ts"))
    }
    private var channels: [ChannelEntity] { [ch(10, 1), ch(20, 2), ch(30, 3), ch(40, 4)] }

    private func opened() -> (Harness, LivePlaybackModel) {
        let harness = Harness()
        let model = harness.makeModel(channels)
        model.start()
        model.openMultiview()
        return (harness, model)
    }

    @Test func openStartsWithOnePaneOnTunedChannel() {
        let (harness, model) = opened()
        #expect(model.overlay == .multiview)
        #expect(model.multiview?.grid.cells.map(\.id) == [10])
        #expect(harness.tiles.count == 1)
        #expect(harness.tiles[0].loaded == ["http://127.0.0.1/10.ts"])
        #expect(harness.tiles.map(\.muted) == [false])
    }

    @Test func okOpensPaneMenuInsteadOfPromoting() {
        let (_, model) = opened()
        #expect(model.onKey(.ok))
        #expect(model.overlay == .multiview)     // still multiview, menu layered on top
        #expect(model.multiview?.menu != nil)
        #expect(model.multiview != nil)          // did NOT promote / tear down to fullscreen
    }

    @Test func menuDownMovesHighlightAndBackClosesToGrid() {
        let (_, model) = opened()
        _ = model.onKey(.ok)
        _ = model.onKey(.down)
        #expect(model.multiview?.menu?.selection == 1)
        _ = model.onKey(.back)                   // BACK closes the menu, keeps the grid
        #expect(model.multiview?.menu == nil)
        #expect(model.overlay == .multiview)
    }

    @Test func fullscreenRowPromotesActivePaneAndExits() {
        let (harness, model) = opened()
        _ = model.onKey(.ok)
        model.runMultiviewMenuRow(.fullscreen)
        #expect(model.overlay == .none)
        #expect(model.multiview == nil)
        #expect(model.current?.id == 10)
        #expect(harness.tiles.allSatisfy { $0.stopCount == 1 && $0.releaseCount == 1 })
    }

    @Test func addPaneViaPickerMintsAndLoadsMutedEngine() {
        let (harness, model) = opened()
        _ = model.onKey(.ok)
        model.runMultiviewMenuRow(.addPane)
        model.selectMultiviewChannel(ch(20, 2))
        #expect(model.multiview?.grid.cells.map(\.id) == [10, 20])
        #expect(harness.tiles.count == 2)
        #expect(harness.tiles[1].loaded == ["http://127.0.0.1/20.ts"])
        #expect(harness.tiles.map(\.muted) == [false, true])
        #expect(model.multiview?.picker == nil)  // picker closed back to grid
    }

    @Test func moveActiveAcrossAddedPanesReMutes() {
        let (harness, model) = opened()
        _ = model.onKey(.ok)
        model.runMultiviewMenuRow(.addPane)
        model.selectMultiviewChannel(ch(20, 2))
        _ = model.onKey(.right)                  // 1×2 grid: active 0 → 1
        #expect(model.multiview?.grid.activeIndex == 1)
        #expect(harness.tiles.map(\.muted) == [true, false])
    }

    @Test func removePaneTearsDownItsEngineAndRelaysOut() {
        let (harness, model) = opened()
        _ = model.onKey(.ok)
        model.runMultiviewMenuRow(.addPane)
        model.selectMultiviewChannel(ch(20, 2))  // 2 panes, active 0
        _ = model.onKey(.ok)                      // reopen menu over active pane 0
        model.runMultiviewMenuRow(.removePane)
        #expect(model.multiview?.grid.cells.map(\.id) == [20])
        #expect(harness.tiles[0].stopCount == 1 && harness.tiles[0].releaseCount == 1)
        #expect(model.multiview?.menu == nil)
    }

    @Test func changeChannelReloadsJustThatPane() {
        let (harness, model) = opened()
        _ = model.onKey(.ok)
        model.runMultiviewMenuRow(.changeChannel)
        model.selectMultiviewChannel(ch(30, 3))
        #expect(model.multiview?.grid.cells.map(\.id) == [30])
        #expect(harness.tiles[0].loaded == ["http://127.0.0.1/10.ts", "http://127.0.0.1/30.ts"])
    }

    @Test func exitClosesEnginesAndRestoresPrimary() {
        let (harness, model) = opened()
        _ = model.onKey(.back)                    // BACK at bare grid exits multiview
        #expect(model.overlay == .none)
        #expect(model.multiview == nil)
        #expect(harness.engine.loaded == ["http://127.0.0.1/10.ts", "http://127.0.0.1/10.ts"])
        #expect(harness.tiles.allSatisfy { $0.stopCount == 1 && $0.releaseCount == 1 })
    }

    @Test func openStopsPrimaryEngineToFreeAudio() {
        let (harness, _) = opened()
        #expect(harness.engine.stopCount == 1)
    }

    @Test func quickBarMultiviewActionOpensSinglePane() {
        let harness = Harness()
        let model = harness.makeModel(channels)
        model.start()
        model.onQuickBarAction(.multiview)
        #expect(model.overlay == .multiview)
        #expect(harness.tiles.count == 1)
    }
}
