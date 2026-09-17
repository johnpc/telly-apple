#if DEBUG
import SwiftUI

/// DEBUG-only Playlist/EPG/Settings screenshot routes (Slice 9), split out to
/// keep `ContentView+Debug` within budget. Seeds the synthetic two-playlist +
/// custom-EPG fixture once (`DebugLaunch.seedPlaylistFixtures`), then pushes the
/// requested Settings pane populated — the Playlists list, one playlist's detail,
/// its EPG-sources or Manage-groups pane, the Backup section (a disabled note on
/// tvOS), or Appearance/About/Other — never touching the real provider.
extension ContentView {
    @ViewBuilder var playlistsDebug: some View {
        if let playlistsModel {
            NavigationStack { playlistsPane(model: playlistsModel) }
        } else {
            Color.black.ignoresSafeArea().task { preparePlaylistsDebug() }
        }
    }

    @ViewBuilder func playlistsPane(model: PlaylistsSettingsModel) -> some View {
        if DebugLaunch.playlistDetailRequested(in: debugArgs) {
            PlaylistDetailScreen(model: model, url: DebugLaunch.demoPlaylistUrl)
        } else if DebugLaunch.epgSourcesRequested(in: debugArgs) {
            EpgSourcesScreen(model: model, url: DebugLaunch.demoPlaylistUrl)
        } else if DebugLaunch.playlistGroupsRequested(in: debugArgs) {
            PlaylistGroupsScreen(model: model, url: DebugLaunch.demoPlaylistUrl)
        } else if DebugLaunch.backupRequested(in: debugArgs) {
            Form { SettingsBackupSectionView(model: env.makeSettingsBackupModel()) }
                .navigationTitle("Settings")
        } else if DebugLaunch.appearanceRequested(in: debugArgs) {
            Form {
                SettingsAppearanceSectionView(settings: env.settings,
                                              makeVisibilityEditModel: env.makeVisibilityEditModel)
                SettingsAboutSectionView()
                SettingsOtherSectionView(settings: env.settings)
            }
            .navigationTitle("Settings")
        } else {
            Form { SettingsPlaylistsSectionView(model: model) }
                .navigationTitle("Playlists")
        }
    }

    func preparePlaylistsDebug() {
        DebugLaunch.seedPlaylistFixtures(playlistStore: env.playlistStore,
                                         epgSourceStore: env.epgSourceStore,
                                         now: { Int64(Date().timeIntervalSince1970 * 1_000) })
        env.reload()
        let model = env.makePlaylistsSettingsModel()
        model.load()
        playlistsModel = model
    }
}
#endif
