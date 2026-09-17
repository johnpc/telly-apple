import SwiftUI

/// Root shell. Onboarding-empty until a playlist exists, then the channel list.
/// Adding a playlist runs the wizard full-screen and reloads on completion.
/// One codebase for iPhone/iPad/Apple TV; per-platform layout lives inside the
/// leaf views, never here.
struct ContentView: View {
    @State private var env = AppEnvironment.makeShared()
    @State private var adding = false
    #if DEBUG
    @State private var liveModel: LivePlaybackModel?
    #endif

    var body: some View {
        #if DEBUG
        debugRoot
        #else
        mainContent
        #endif
    }

    private var mainContent: some View {
        Group {
            if env.playlists.isEmpty {
                WelcomeView(onAdd: { adding = true })
            } else {
                ChannelListScreen(channelStore: env.channelStore,
                                  makeEngine: env.makeEngine,
                                  onAdd: { adding = true })
            }
        }
        .fullScreenCover(isPresented: $adding) {
            AddPlaylistScreen(model: env.makeAddPlaylistModel()) {
                adding = false
                env.reload()
            }
        }
    }

    #if DEBUG
    private var debugArgs: [String] { ProcessInfo.processInfo.arguments }

    @ViewBuilder private var debugRoot: some View {
        if DebugLaunch.liveDemoRequested(in: debugArgs) {
            liveDemo
        } else if let url = DebugLaunch.autoplayUrl(in: debugArgs) {
            PlaybackScreen(streamUrl: url, engine: env.makeEngine())
        } else {
            mainContent.task { seedDebugFixtures() }
        }
    }

    @ViewBuilder private var liveDemo: some View {
        if let liveModel {
            LivePlaybackScreen(model: liveModel)
        } else {
            Color.black.ignoresSafeArea().task { prepareLiveDemo() }
        }
    }

    private func prepareLiveDemo() {
        seedDebugFixtures()
        let model = env.makeLivePlaybackModel()
        if DebugLaunch.forcedZapOverlay(in: debugArgs) { model.debugPresentZapOverlay() }
        liveModel = model
    }

    private func seedDebugFixtures() {
        DebugLaunch.seedIfRequested(into: env.playlistStore, args: debugArgs,
                                    now: { Int64(Date().timeIntervalSince1970 * 1000) })
        env.reload()
    }
    #endif
}

#Preview {
    ContentView()
}
