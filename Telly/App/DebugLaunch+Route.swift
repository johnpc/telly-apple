#if DEBUG
import Foundation

/// The ONE place the DEBUG launch arguments resolve into a screen. Every
/// screenshot / UI-verification entry point is a case here, so the harness is
/// enumerable (an agent or a script can list every route), the precedence
/// between flags is pinned by a unit test rather than by the order of an
/// `else if` chain, and `ContentView` switches over it exhaustively — adding a
/// route without rendering it is a compile error. Never compiled into release.
extension DebugLaunch {
    enum Route: Equatable {
        case loadState(LoadStateDemo)
        case settings
        case feedbackProof
        case playlists
        case guide
        case history
        case search
        case groups
        case vodBrowse
        case vodPlayback
        case catchupTransport
        case catchup
        case multiview
        case live
        case myList
        case autoplay(url: String)
        /// No route flag: the normal app, after the fixture / demo seeds (if any).
        case main
    }

    /// Whether the `-tellyFeedbackProof` action-feedback proof was requested.
    static func feedbackProofRequested(in args: [String]) -> Bool { args.contains("-tellyFeedbackProof") }

    /// Whether the `-tellyMultiviewDemo` engine-free grid proof was requested.
    static func multiviewDemoRequested(in args: [String]) -> Bool { args.contains("-tellyMultiviewDemo") }

    /// Whether `-tellyDemo` asked to install the built-in demo playlist on launch
    /// (the release-safe `DemoContent`, so screenshots and QA need no server).
    static func demoRequested(in args: [String]) -> Bool { args.contains("-tellyDemo") }

    /// Resolves the launch arguments to the single route to present. Earlier
    /// entries win when several flags are passed (the historical precedence).
    static func route(in args: [String]) -> Route {
        if let demo = loadStateDemo(in: args) { return .loadState(demo) }
        if settingsRequested(in: args) { return .settings }
        if feedbackProofRequested(in: args) { return .feedbackProof }
        if playlistDebugRequested(in: args) { return .playlists }
        if forcedGuide(in: args) { return .guide }
        if historyDemoRequested(in: args) { return .history }
        if searchDebugRequested(in: args) { return .search }
        if groupsDebugRequested(in: args) { return .groups }
        if vodBrowseRequested(in: args) { return .vodBrowse }
        if vodPlaybackRequested(in: args) { return .vodPlayback }
        if catchupTransportRequested(in: args) { return .catchupTransport }
        if catchupDemoRequested(in: args) { return .catchup }
        if multiviewDemoRequested(in: args) { return .multiview }
        if liveDemoRequested(in: args) { return .live }
        if myListSeedRequested(in: args) { return .myList }
        if let url = autoplayUrl(in: args) { return .autoplay(url: url) }
        return .main
    }
}
#endif
