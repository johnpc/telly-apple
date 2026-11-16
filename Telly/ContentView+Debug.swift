#if DEBUG
import SwiftUI

/// DEBUG-only launch-argument routing for `ContentView`: resolves the arguments
/// to ONE ``DebugLaunch/Route`` and renders it (exhaustively — a new route must
/// be rendered to compile), seeding local fixtures per proof and never touching
/// the real provider.
extension ContentView {
    var debugArgs: [String] { ProcessInfo.processInfo.arguments }

    @ViewBuilder var debugRoot: some View {
        switch DebugLaunch.route(in: debugArgs) {
        case let .loadState(demo): loadStateDemo(demo)
        case .settings: settingsDebug
        case .feedbackProof: feedbackProof
        case .playlists: playlistsDebug
        case .guide: guideDemo
        case .history: historyDemo
        case .search: searchDebug
        case .groups: groupsDebug
        case .vodBrowse: vodBrowseDemo
        case .vodPlayback: vodPlaybackDemo
        case .catchupTransport: catchupTransportDemo
        case .catchup: catchupDemo
        case .multiview: multiviewDemo
        case .live: liveDemo
        case .myList: myListDemo
        case let .autoplay(url): PlaybackScreen(streamUrl: url, engine: env.makeEngine())
        case .main: mainContent.task { await seedMainIfRequested() }
        }
    }

    private var settingsDebug: some View {
        SettingsScreen(settings: env.settings,
                       backup: env.makeSettingsBackupModel(),
                       playlists: env.makePlaylistsSettingsModel(),
                       makeVisibilityEditModel: env.makeVisibilityEditModel,
                       clearVodPositions: env.clearVodPositions, onClose: {})
    }

    /// `-tellyDemo` on ANY route: install the built-in provider first, so every
    /// screenshot proof can run over the demo channels + guide instead of fixtures.
    func installDemoIfRequested() async {
        if DebugLaunch.demoRequested(in: debugArgs) { await env.installDemoPlaylist() }
    }

    /// The `.main` route's seeds: local fixtures, the built-in demo playlist, and
    /// the env-driven real-provider imports — each a no-op unless requested.
    private func seedMainIfRequested() async {
        seedDebugFixtures()
        await installDemoIfRequested()
        await env.seedRealPlaylistIfRequested(environment: ProcessInfo.processInfo.environment)
        await env.seedXtreamIfRequested(environment: ProcessInfo.processInfo.environment)
    }

    func seedDebugFixtures() {
        DebugLaunch.seedIfRequested(into: env.playlistStore, args: debugArgs,
                                    now: { Int64(Date().timeIntervalSince1970 * 1000) })
        env.reload()
        DebugLaunch.seedFavoritesIfRequested(into: env.channelStore, args: debugArgs)
        if let group = DebugLaunch.forcedChannelGroup(in: debugArgs) {
            env.channelListModel.select(group)
        }
        env.channelListModel.load()
        if let q = DebugLaunch.forcedChannelSearch(in: debugArgs) {
            env.channelListModel.query = q
        }
    }
}
#endif
