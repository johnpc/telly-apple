import Testing
@testable import Telly

/// The shared live-engine owner: `acquire` mints once and hands back the SAME
/// engine until `exit`; the stage follows the hosted model's tunes; the guide flag
/// only exists while live; `exit` stops, releases and resets so the next acquire
/// mints afresh.
@MainActor
struct LiveEngineStoreTests {
    private func makeStore() -> LiveEngineStore { LiveEngineStore(makeEngine: { FakePlayerEngine() }) }

    @Test func acquireMintsOnceAndReusesTheSameEngine() {
        let store = makeStore()
        let first = store.acquire() as AnyObject
        #expect(store.acquire() as AnyObject === first)
        #expect(store.engine as AnyObject === first)
    }

    @Test func stageFollowsTunesAndKeepsTheGuideFlag() {
        let store = makeStore()
        #expect(store.stage == .idle)
        store.showGuide()                       // inert while idle
        #expect(store.stage == .idle)
        _ = store.acquire()
        store.noteTuned("http://a")
        #expect(store.stage == .live(url: "http://a", guideVisible: false))
        #expect(store.currentUrl == "http://a")
        store.showGuide()
        store.noteTuned("http://b")             // a zap from the guide keeps it up
        #expect(store.stage == .live(url: "http://b", guideVisible: true))
        store.hideGuide()
        #expect(!store.guideVisible)
    }

    @Test func exitStopsReleasesAndResets() {
        let store = makeStore()
        let engine = store.acquire() as! FakePlayerEngine  // swiftlint:disable:this force_cast
        store.noteTuned("http://a"); store.showGuide()
        store.exit()
        #expect(engine.stopCount == 1 && engine.releaseCount == 1)
        #expect(store.engine == nil)
        #expect(store.stage == .idle)
        #expect(store.acquire() as AnyObject !== engine)
    }
}
