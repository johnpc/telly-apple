import Testing
@testable import Telly

/// The live orchestrator's multiview entry/move/promote/exit, composed over the
/// `makeEngine` tile factory and ``FakePlayerEngine`` so every load, mute and
/// teardown is asserted without VLCKit. Mirrors ``LivePlaybackModelTests``.
@MainActor
struct LivePlaybackMultiviewTests {
    /// Captures the tile engines the model mints via `makeEngine`, plus the
    /// single primary engine, so their loads/mutes/teardown can be inspected.
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

    @Test func openBuildsSessionOverlayAndLoadsMuted() {
        let harness = Harness()
        let model = harness.makeModel(channels)
        model.start()
        _ = model.onKey(.menu)             // → quick bar
        #expect(model.onKey(.ok))          // quick-bar OK is the v1 multiview entry
        #expect(model.overlay == .multiview)
        #expect(model.multiview != nil)
        #expect(harness.tiles.count == 4)
        #expect(harness.tiles[0].loaded == ["http://127.0.0.1/10.ts"])
        #expect(harness.tiles.map(\.muted) == [false, true, true, true])
    }

    @Test func moveUpdatesActiveAndAudio() {
        let harness = Harness()
        let model = harness.makeModel(channels)
        model.start()
        model.openMultiview()
        _ = model.onKey(.right)            // active 0 → 1 in the 2×2 grid
        #expect(model.multiview?.grid.activeIndex == 1)
        #expect(harness.tiles.map(\.muted) == [true, false, true, true])
    }

    @Test func promoteExitsAndTunesActiveCell() {
        let harness = Harness()
        let model = harness.makeModel(channels)
        model.start()
        model.openMultiview()
        _ = model.onKey(.right)            // active → ch20
        _ = model.onKey(.ok)               // promote to fullscreen
        #expect(model.overlay == .none)
        #expect(model.multiview == nil)
        #expect(model.current?.id == 20)
        #expect(harness.tiles.allSatisfy { $0.stopCount == 1 && $0.releaseCount == 1 })
    }

    @Test func exitClosesEnginesAndResets() {
        let harness = Harness()
        let model = harness.makeModel(channels)
        model.start()
        model.openMultiview()
        _ = model.onKey(.back)             // exit
        #expect(model.overlay == .none)
        #expect(model.multiview == nil)
        #expect(harness.tiles.allSatisfy { $0.stopCount == 1 && $0.releaseCount == 1 })
    }
}
