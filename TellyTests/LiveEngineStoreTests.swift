import Testing
@testable import Telly

/// The shared live-engine lifetime and guide-overlay state machine: the engine is
/// minted once and reused across a guide round-trip (no reconnect), a repeat tune
/// of the current URL is a no-op, a new URL loads on the SAME instance, and only a
/// real `exit` stops/releases it — after which the next `play` mints a fresh one.
@MainActor
struct LiveEngineStoreTests {
    private func makeStore() -> LiveEngineStore {
        LiveEngineStore(makeEngine: { FakePlayerEngine() })
    }

    private func fake(_ store: LiveEngineStore) -> FakePlayerEngine {
        store.engine as! FakePlayerEngine  // swiftlint:disable:this force_cast
    }

    @Test func firstPlayMintsEngineAndLoadsLive() {
        let store = makeStore()
        store.play("http://a")
        #expect(fake(store).loaded == ["http://a"])
        #expect(fake(store).loadedLive == [true])
    }

    @Test func repeatSameUrlDoesNotReload() {
        let store = makeStore()
        store.play("http://a")
        let engine = store.engine as AnyObject
        store.play("http://a")
        #expect(fake(store).loaded == ["http://a"])
        #expect(store.engine as AnyObject === engine)
    }

    @Test func newUrlTunesSameInstance() {
        let store = makeStore()
        store.play("http://a")
        let engine = store.engine as AnyObject
        store.play("http://b")
        #expect(store.engine as AnyObject === engine)
        #expect(fake(store).loaded == ["http://a", "http://b"])
    }

    @Test func guideRoundTripKeepsEngineAlive() {
        let store = makeStore()
        store.play("http://a")
        let engine = store.engine as AnyObject
        store.showGuide()
        #expect(store.guideVisible)
        store.hideGuide()
        #expect(!store.guideVisible)
        #expect(store.engine as AnyObject === engine)
        #expect(fake(store).loaded == ["http://a"])
        #expect(fake(store).stopCount == 0)
        #expect(fake(store).releaseCount == 0)
    }

    @Test func exitStopsReleasesAndResets() {
        let store = makeStore()
        store.play("http://a")
        store.showGuide()
        let engine = store.engine as! FakePlayerEngine  // swiftlint:disable:this force_cast
        store.exit()
        #expect(engine.stopCount == 1)
        #expect(engine.releaseCount == 1)
        #expect(store.engine == nil)
        #expect(store.currentUrl == nil)
        #expect(!store.guideVisible)
    }

    @Test func playAfterExitMintsFreshEngine() {
        let store = makeStore()
        store.play("http://a")
        let first = store.engine as AnyObject
        store.exit()
        store.play("http://a")
        #expect(store.engine as AnyObject !== first)
        #expect(fake(store).loaded == ["http://a"])
    }
}
