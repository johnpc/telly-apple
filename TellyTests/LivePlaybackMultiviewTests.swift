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

    private func ch(_ id: Int, _ number: Int, blocked: Bool = false) -> ChannelEntity {
        ChannelEntity(id: id, playlistId: 1, number: number, sortIndex: number,
                      source: ChannelSource(name: "Ch\(id)", groupTitle: "Live",
                                            streamUrl: "http://127.0.0.1/\(id).ts"),
                      flags: ChannelFlags(blocked: blocked))
    }
    private var channels: [ChannelEntity] { [ch(10, 1), ch(20, 2), ch(30, 3), ch(40, 4)] }

    private func armedGate() -> PlaybackBlockGate {
        let p = ParentalStore(secret: InMemorySecretStore(), backing: InMemoryKeyValueStore())
        p.set(pin: "1234"); p.isEnabled = true
        return PlaybackBlockGate(parental: p)
    }

    private func gatedModel(_ harness: Harness, _ channels: [ChannelEntity],
                            gate: PlaybackBlockGate, stored: Int?) -> LivePlaybackModel {
        LivePlaybackModel(
            engine: harness.engine, channels: channels,
            makeEngine: { let e = FakePlayerEngine(); harness.tiles.append(e); return e },
            now: { harness.clock }, persistLastChannel: { _ in },
            loadLastChannel: { stored }, onExitToGuide: {}, blockGate: gate)
    }

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

    // MARK: Bug 1 — the primary engine is freed on open, restored on close.

    @Test func openStopsPrimaryEngineToFreeAudio() {
        let harness = Harness()
        let model = harness.makeModel(channels)
        model.start()
        #expect(harness.engine.loaded == ["http://127.0.0.1/10.ts"])
        model.openMultiview()
        #expect(harness.engine.stopCount == 1)     // primary freed → no double audio
    }

    @Test func exitRestoresPrimaryPlaybackOfActiveChannel() {
        let harness = Harness()
        let model = harness.makeModel(channels)
        model.start()
        model.openMultiview()
        model.exitMultiview()
        #expect(harness.engine.stopCount == 1)
        // reloaded the previously-active channel on the primary engine
        #expect(harness.engine.loaded == ["http://127.0.0.1/10.ts", "http://127.0.0.1/10.ts"])
        #expect(harness.tiles.allSatisfy { $0.stopCount == 1 && $0.releaseCount == 1 })
    }

    // MARK: Bug 3 — the iPhone/iPad quick-bar `.multiview` tap opens multiview.

    @Test func quickBarMultiviewActionOpensMultiviewOnTouchPath() {
        let harness = Harness()
        let model = harness.makeModel(channels)
        model.start()
        model.onQuickBarAction(.multiview)         // the compact quick-bar tap entry
        #expect(model.overlay == .multiview)
        #expect(model.multiview != nil)
        #expect(harness.tiles.count == 4)
    }

    // MARK: Bug 2 — multiview tile tunes route through the parental block gate.

    @Test func openMultiviewGatesBlockedActiveChannel() {
        let harness = Harness()
        let gate = armedGate()
        let model = gatedModel(harness, [ch(10, 1, blocked: true)], gate: gate, stored: 10)
        model.start()                              // intercepted → current nil
        #expect(model.submitBlockPin("1234"))      // unlock → tunes ch10 fullscreen
        #expect(model.current?.id == 10)
        model.openMultiview()                      // active still blocked → re-prompt
        #expect(model.multiview == nil)
        #expect(model.overlay != .multiview)
        #expect(gate.pending?.id == 10)
        #expect(harness.tiles.isEmpty)             // no tile engine minted
        #expect(harness.engine.stopCount == 0)     // primary not stopped (never opened)
    }

    @Test func openMultiviewSkipsBlockedNonActiveTiles() {
        let harness = Harness()
        let gate = armedGate()
        let model = gatedModel(harness, [ch(10, 1), ch(20, 2, blocked: true)],
                               gate: gate, stored: 10)
        model.start()
        model.openMultiview()
        #expect(model.multiview != nil)            // active unblocked → opens
        #expect(gate.pending == nil)
        #expect(harness.tiles.count == 2)
        #expect(harness.tiles[0].loaded == ["http://127.0.0.1/10.ts"])   // active decodes
        #expect(harness.tiles[1].loaded.isEmpty)                         // blocked stays black
    }
}
