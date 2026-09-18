#if DEBUG
import Testing
@testable import Telly

/// The `-tellyLoadState` screenshot flag parser and its phase mapping.
struct DebugLaunchLoadStateTests {
    @Test func parsesEachKnownState() {
        #expect(DebugLaunch.loadStateDemo(in: ["-tellyLoadState", "loading"]) == .loading)
        #expect(DebugLaunch.loadStateDemo(in: ["-tellyLoadState", "empty"]) == .empty)
        #expect(DebugLaunch.loadStateDemo(in: ["-tellyLoadState", "error"]) == .error)
    }

    @Test func nilWhenAbsentOrUnknown() {
        #expect(DebugLaunch.loadStateDemo(in: []) == nil)
        #expect(DebugLaunch.loadStateDemo(in: ["-tellyLoadState", "bogus"]) == nil)
    }

    @Test func mapsToLoadPhase() {
        #expect(DebugLaunch.LoadStateDemo.loading.phase == .loading)
        #expect(DebugLaunch.LoadStateDemo.empty.phase == .empty)
        #expect(DebugLaunch.LoadStateDemo.error.phase == .failed)
    }
}
#endif
