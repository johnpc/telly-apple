import SwiftUI

/// Root shell. Onboarding-empty until a playlist exists, then the channel list.
/// Adding a playlist runs the wizard full-screen and reloads on completion.
/// One codebase for iPhone/iPad/Apple TV; per-platform layout lives inside the
/// leaf views. DEBUG launch-arg routing lives in `ContentView+Debug`.
struct ContentView: View {
    @State var env = AppEnvironment.makeShared()
    @State var adding = false
    #if DEBUG
    @State var liveModel: LivePlaybackModel?
    @State var guideModel: GuideGridModel?
    @State var historyModel: HistoryListModel?
    @State var multiviewSession: MultiviewSession?
    @State var catchupTarget: GuidePlaybackTarget?
    @State var catchupTransportModel: CatchupPlaybackModel?
    #endif

    var body: some View {
        #if DEBUG
        debugRoot
        #else
        mainContent
        #endif
    }

    var mainContent: some View {
        Group {
            if env.playlists.isEmpty {
                WelcomeView(onAdd: { adding = true })
            } else {
                ChannelListScreen(model: env.channelListModel,
                                  makeEngine: env.makeEngine,
                                  makeGuideGridModel: env.makeGuideGridModel,
                                  makeCatchupModel: env.makeCatchupPlaybackModel,
                                  makeHistoryModel: env.makeHistoryModel,
                                  makeChannelEditModel: env.makeChannelEditModel,
                                  makeVisibilityEditModel: env.makeVisibilityEditModel,
                                  makeBackupModel: env.makeSettingsBackupModel,
                                  settings: env.settings,
                                  parental: env.parentalStore,
                                  onAdd: { adding = true })
            }
        }
        .fullScreenCover(isPresented: $adding) {
            AddPlaylistScreen(model: env.makeAddPlaylistModel()) {
                adding = false
                env.reload()
            }
        }
        .task {
            await env.refreshEpgIfDue()
            await env.refreshPlaylistsOnStart()
        }
    }
}

#Preview {
    ContentView()
}
