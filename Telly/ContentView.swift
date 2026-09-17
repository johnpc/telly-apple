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
                ChannelListScreen(channelStore: env.channelStore,
                                  makeEngine: env.makeEngine,
                                  makeGuideGridModel: env.makeGuideGridModel,
                                  onAdd: { adding = true })
            }
        }
        .fullScreenCover(isPresented: $adding) {
            AddPlaylistScreen(model: env.makeAddPlaylistModel()) {
                adding = false
                env.reload()
            }
        }
        .task { await env.refreshEpgIfDue() }
    }
}

#Preview {
    ContentView()
}
