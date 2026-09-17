import Testing
import GRDB
@testable import Telly

/// The VOD playback orchestrator, composed over ``FakePlayerEngine`` + REAL
/// in-memory VOD stores and a manual integer clock so every timed decision is
/// deterministic. Mirrors the Android `VodPlaybackViewModelTest` matrix.
@MainActor
struct VodPlaybackModelTests {
    @MainActor
    final class Harness {
        let engine = FakePlayerEngine()
        let itemStore: VodItemStore
        let positionStore: VodPositionStore
        var clock = 0
        var exitCount = 0

        init(remember: Bool = true) {
            let db = try! AppDatabase.makeInMemory()
            itemStore = VodItemStore(db: db)
            positionStore = VodPositionStore(db: db, remember: { remember }, clock: { 999 })
        }

        func seedItem() throws {
            try itemStore.replace(playlistId: 1, items: [
                VodItem(id: nil, playlistId: 1, sortIndex: 0, itemKey: "k", name: "Big Buck Bunny",
                        groupTitle: "Action", logoUrl: nil, streamUrl: "http://s/k.mp4")])
        }

        func seedPosition(_ positionMs: Int, _ durationMs: Int) throws {
            try positionStore.save(itemKey: "k", positionMs: positionMs, durationMs: durationMs)
        }

        func model() -> VodPlaybackModel {
            VodPlaybackModel(engine: engine, itemStore: itemStore, positionStore: positionStore,
                             itemKey: "k", now: { self.clock }, onExit: { self.exitCount += 1 })
        }
    }

    @Test func noStoredPositionPlaysFromStart() throws {
        let h = Harness()
        try h.seedItem()
        let model = h.model()
        model.start()
        #expect(model.stage == .playing)
        #expect(h.engine.loaded == ["http://s/k.mp4"])
        #expect(h.engine.seeks.isEmpty)
        #expect(model.visibility.visible)
    }

    @Test func storedMidBandOffersResumeThenSeeksOnResume() throws {
        let h = Harness()
        try h.seedItem()
        try h.seedPosition(12_000, 30_000)
        let model = h.model()
        model.start()
        #expect(model.stage == .resumePrompt(positionMs: 12_000))
        #expect(h.engine.loaded.isEmpty)
        model.resumeStored()
        #expect(model.stage == .playing)
        #expect(h.engine.seeks == [12_000])
    }

    @Test func startOverPlaysFromTheBeginning() throws {
        let h = Harness()
        try h.seedItem()
        try h.seedPosition(12_000, 30_000)
        let model = h.model()
        model.start()
        model.startOver()
        #expect(model.stage == .playing)
        #expect(h.engine.seeks.isEmpty)
    }

    @Test func positionOutsideTheBandSkipsThePrompt() throws {
        let h = Harness()
        try h.seedItem()
        try h.seedPosition(500, 30_000)
        let model = h.model()
        model.start()
        #expect(model.stage == .playing)
    }

    @Test func exitPersistsOnceAndLeaves() throws {
        let h = Harness()
        try h.seedItem()
        let model = h.model()
        model.start()
        h.engine.positionMs = 4_000
        h.engine.durationMs = 30_000
        model.exit()
        model.exit()
        let row = try #require(try h.positionStore.read(itemKey: "k"))
        #expect(row.positionMs == 4_000)
        #expect(row.durationMs == 30_000)
        #expect(h.exitCount == 1)
    }

    @Test func exitBeforePlayingJustLeavesWithoutPersisting() throws {
        let h = Harness()
        try h.seedItem()
        try h.seedPosition(12_000, 30_000)
        let model = h.model()
        model.start()
        #expect(model.stage == .resumePrompt(positionMs: 12_000))
        model.exit()
        #expect(h.exitCount == 1)
        #expect(try h.positionStore.read(itemKey: "k")?.positionMs == 12_000)
    }

    @Test func positionPersistsEveryTenSeconds() throws {
        let h = Harness()
        try h.seedItem()
        let model = h.model()
        model.start()
        h.engine.positionMs = 9_500
        h.engine.durationMs = 30_000
        h.clock = 9_000
        model.tick()
        #expect(try h.positionStore.all().isEmpty)
        h.clock = 10_000
        model.tick()
        #expect(try h.positionStore.read(itemKey: "k")?.positionMs == 9_500)
    }

    @Test func mediaEndClearsThePositionAndExits() throws {
        let h = Harness()
        try h.seedItem()
        try h.seedPosition(12_000, 30_000)
        let model = h.model()
        model.start()
        model.startOver()
        h.engine.positionMs = 30_000
        h.engine.durationMs = 30_000
        h.engine.state = .ended
        model.tick()
        #expect(try h.positionStore.read(itemKey: "k") == nil)
        #expect(h.exitCount == 1)
    }

    @Test func vanishedItemJustLeavesTheRoute() {
        let h = Harness()
        let model = h.model()
        model.start()
        #expect(model.stage == .loading)
        #expect(h.exitCount == 1)
    }

    @Test func togglePausePersistsOnPauseThenResumes() throws {
        let h = Harness()
        try h.seedItem()
        let model = h.model()
        model.start()
        h.engine.positionMs = 4_000
        h.engine.durationMs = 30_000
        model.togglePause()
        #expect(h.engine.paused)
        #expect(try h.positionStore.read(itemKey: "k")?.positionMs == 4_000)
        model.togglePause()
        #expect(!h.engine.paused)
    }

    @Test func seekByUsesTheStepConstantsAndClamps() throws {
        let h = Harness()
        try h.seedItem()
        let model = h.model()
        model.start()
        h.engine.durationMs = 30_000
        h.engine.positionMs = 5_000
        model.seekBy(VodPlaybackModel.seekStepMs)
        #expect(h.engine.positionMs == 15_000)
        h.engine.positionMs = 25_000
        model.seekBy(VodPlaybackModel.jumpStepMs)
        #expect(h.engine.positionMs == 30_000)
        model.seekBy(-VodPlaybackModel.jumpStepMs)
        #expect(h.engine.positionMs == 0)
    }

    @Test func progressIsPausedAndTransportPoke() throws {
        let h = Harness()
        try h.seedItem()
        let model = h.model()
        model.start()
        h.engine.positionMs = 4_000
        h.engine.durationMs = 8_000
        #expect(model.progress == VodProgress(positionMs: 4_000, durationMs: 8_000))
        #expect(model.isPaused == false)
        h.clock = 100_000
        model.tick()
        #expect(model.visibility.visible == false)
        model.pokeTransport()
        #expect(model.visibility.visible)
    }
}
