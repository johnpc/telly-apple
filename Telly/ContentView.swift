import SwiftUI

/// Root shell. Onboarding-empty until a playlist exists, then the channel list.
/// Adding a playlist runs the wizard full-screen and reloads on completion.
/// One codebase for iPhone/iPad/Apple TV; per-platform layout lives inside the
/// leaf views, never here.
struct ContentView: View {
    @State private var env = AppEnvironment.makeShared()
    @State private var adding = false

    var body: some View {
        #if DEBUG
        if let url = DebugLaunch.autoplayUrl(in: ProcessInfo.processInfo.arguments) {
            PlaybackScreen(streamUrl: url, engine: env.makeEngine())
        } else {
            mainContent.task { seedDebugFixtures() }
        }
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
    private func seedDebugFixtures() {
        DebugLaunch.seedIfRequested(into: env.playlistStore,
                                    args: ProcessInfo.processInfo.arguments,
                                    now: { Int64(Date().timeIntervalSince1970 * 1000) })
        env.reload()
    }
    #endif
}

#Preview {
    ContentView()
}
