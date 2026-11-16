#if DEBUG
import Testing
@testable import Telly

/// The DEBUG launch router: every flag resolves to its route, no flag is the
/// normal app, and the precedence between simultaneous flags is pinned here
/// instead of living implicitly in a view's `else if` order.
struct DebugLaunchRouteTests {
    @Test func noFlagIsTheMainApp() {
        #expect(DebugLaunch.route(in: ["Telly"]) == .main)
        #expect(DebugLaunch.route(in: ["Telly", "-tellyDemo"]) == .main)   // a seed, not a route
    }

    struct Row: Sendable { let flag: String; let route: DebugLaunch.Route }
    static let rows: [Row] = [
        Row(flag: "-tellySettings", route: .settings),
        Row(flag: "-tellyFeedbackProof", route: .feedbackProof),
        Row(flag: "-tellyPlaylists", route: .playlists),
        Row(flag: "-tellyBackup", route: .playlists),
        Row(flag: "-tellyGuide", route: .guide),
        Row(flag: "-tellyHistorySeed", route: .history),
        Row(flag: "-tellySearch", route: .search),
        Row(flag: "-tellyManageGroups", route: .groups),
        Row(flag: "-tellyVodBrowse", route: .vodBrowse),
        Row(flag: "-tellyVodPlayback", route: .vodPlayback),
        Row(flag: "-tellyCatchupTransport", route: .catchupTransport),
        Row(flag: "-tellyCatchup", route: .catchup),
        Row(flag: "-tellyMultiviewDemo", route: .multiview),
        Row(flag: "-tellyLiveDemo", route: .live),
        Row(flag: "-tellyMyListSeed", route: .myList),
    ]

    @Test(arguments: rows)
    func eachFlagResolvesToItsRoute(_ row: Row) {
        #expect(DebugLaunch.route(in: ["Telly", row.flag]) == row.route)
    }

    @Test func valueFlagsCarryTheirPayload() {
        #expect(DebugLaunch.route(in: ["Telly", "-tellyLoadState", "error"]) == .loadState(.error))
        #expect(DebugLaunch.route(in: ["Telly", "-tellyAutoplayUrl", "http://127.0.0.1/a.ts"])
                == .autoplay(url: "http://127.0.0.1/a.ts"))
    }

    @Test func precedenceIsLoadStateThenSettingsDownToAutoplay() {
        let everything = ["Telly", "-tellyAutoplayUrl", "http://x", "-tellyLiveDemo", "-tellySettings",
                          "-tellyLoadState", "empty"]
        #expect(DebugLaunch.route(in: everything) == .loadState(.empty))
        #expect(DebugLaunch.route(in: ["Telly", "-tellyLiveDemo", "-tellySettings"]) == .settings)
        #expect(DebugLaunch.route(in: ["Telly", "-tellyAutoplayUrl", "http://x", "-tellyLiveDemo"]) == .live)
    }

    @Test func demoAndFeedbackFlagsAreReadByName() {
        #expect(DebugLaunch.demoRequested(in: ["Telly", "-tellyDemo"]))
        #expect(!DebugLaunch.demoRequested(in: ["Telly"]))
        #expect(DebugLaunch.feedbackProofRequested(in: ["Telly", "-tellyFeedbackProof"]))
        #expect(DebugLaunch.multiviewDemoRequested(in: ["Telly", "-tellyMultiviewDemo"]))
    }
}
#endif
