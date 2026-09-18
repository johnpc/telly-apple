import SwiftUI

/// Root shell. Onboarding-empty until a playlist exists, then the channel list.
/// Adding a playlist runs the wizard full-screen and reloads on completion.
/// One codebase for iPhone/iPad/Apple TV; per-platform layout lives inside the
/// leaf views. DEBUG launch-arg routing lives in `ContentView+Debug`.
struct ContentView: View {
    @State var env = AppEnvironment.makeShared()
    @State var adding = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    #if DEBUG
    @State var liveModel: LivePlaybackModel?
    @State var guideModel: GuideGridModel?
    @State var historyModel: HistoryListModel?
    @State var searchModel: SearchModel?
    @State var multiviewSession: MultiviewSession?
    @State var catchupTarget: GuidePlaybackTarget?
    @State var catchupTransportModel: CatchupPlaybackModel?
    @State var playlistsModel: PlaylistsSettingsModel?
    @State var groupsSeeded = false
    @State var vodModel: VodBrowseModel?
    @State var vodPlaybackModel: VodPlaybackModel?
    @State var myListModel: MyListModel?
    #endif

    var body: some View {
        rootContent
            .preferredColorScheme(env.settings.appearanceTheme.colorScheme)
    }

    @ViewBuilder private var rootContent: some View {
        #if DEBUG
        debugRoot
        #else
        mainContent
        #endif
    }

    var mainContent: some View {
        Group {
            if env.playlists.isEmpty {
                WelcomeView(onAdd: { adding = true }).routeTransition()
            } else {
                makeChannelListScreen().routeTransition()
            }
        }
        .animation(Motion.gated(Motion.route, reduceMotion: reduceMotion),
                   value: env.playlists.isEmpty)
        .fullScreenCover(isPresented: $adding) {
            AddPlaylistScreen(model: env.makeAddPlaylistModel()) {
                adding = false
                env.reload()
            }
        }
        // Playlist refresh-on-start is now owned by the channel list's load seam
        // (`ChannelListModel.start` → `reloadChannels`); only the EPG stays here.
        .task { await env.refreshEpgIfDue() }
    }
}

#Preview {
    ContentView()
}
