#if DEBUG
import SwiftUI

/// DEBUG-only custom-groups screenshot routes (Slice 7), split out to keep
/// `ContentView+Debug` within budget. Seeds the synthetic playlist + now-airing
/// EPG + two pre-created custom groups once (`DebugLaunch.seedGroupsFixtures` /
/// `seedCustomGroups`), then presents the requested Settings pane — Manage
/// Groups, Assign EPG or Copy channels — or, for `-tellyGroupsStrip`, the
/// channel list with a populated custom group selected. Never touches the real
/// provider.
extension ContentView {
    @ViewBuilder var groupsDebug: some View {
        if groupsSeeded {
            if DebugLaunch.groupsStripRequested(in: debugArgs) {
                mainContent
            } else {
                NavigationStack { groupsPane(playlists: env.makePlaylistsSettingsModel()) }
            }
        } else {
            Color.black.ignoresSafeArea().task { prepareGroupsDebug() }
        }
    }

    @ViewBuilder func groupsPane(playlists: PlaylistsSettingsModel) -> some View {
        if DebugLaunch.assignEpgRequested(in: debugArgs) {
            assignEpgPane(playlists.makeEpgAssignmentModel())
        } else if DebugLaunch.copyChannelsRequested(in: debugArgs) {
            CopyChannelsScreen(model: playlists.makeCopyChannelsModel())
        } else {
            ManageGroupsScreen(model: playlists.makeManageGroupsModel(),
                               makeCopyChannelsModel: playlists.makeCopyChannelsModel)
        }
    }

    /// Drills straight into the first channel's Assign-EPG picker (Auto + the
    /// seeded EPG ids) so the shot proves the picker, falling back to the entry
    /// list when there are no channels.
    @ViewBuilder func assignEpgPane(_ model: EpgAssignmentModel) -> some View {
        if let channel = (try? env.channelStore.allChannels())?.first {
            AssignEpgScreen(model: model.assignModel(for: channel))
        } else {
            EpgAssignmentScreen(model: model)
        }
    }

    func prepareGroupsDebug() {
        DebugLaunch.seedGroupsFixtures(
            playlistStore: env.playlistStore, programStore: env.programStore,
            now: { Int(Date().timeIntervalSince1970 * 1_000) })
        env.reload()
        DebugLaunch.seedCustomGroups(store: CustomGroupStore(db: env.channelStore.db))
        env.channelListModel.load()
        if DebugLaunch.groupsStripRequested(in: debugArgs) {
            env.channelListModel.select(DebugLaunch.groupsStripName)
        }
        groupsSeeded = true
    }
}
#endif
