import SwiftUI

/// Builds the post-onboarding channel list from the environment's factories in
/// one place, so the release route and the DEBUG screenshot harness share the
/// exact same construction (the duplication gate flags copies). `autoStart` lets
/// the harness pin a load phase without the real load overwriting it.
extension ContentView {
    func makeChannelListScreen(autoStart: Bool = true) -> ChannelListScreen {
        ChannelListScreen(model: env.channelListModel,
                          makeEngine: env.makeEngine,
                          makeGuideGridModel: env.makeGuideGridModel,
                          makeCatchupModel: env.makeCatchupPlaybackModel,
                          makeHistoryModel: env.makeHistoryModel,
                          makeSearchModel: env.makeSearchModel,
                          makeChannelEditModel: env.makeChannelEditModel,
                          makeVisibilityEditModel: env.makeVisibilityEditModel,
                          makeBackupModel: env.makeSettingsBackupModel,
                          makePlaylistsSettingsModel: env.makePlaylistsSettingsModel,
                          makeVodBrowseModel: env.makeVodBrowseModel,
                          makeVodPlaybackModel: env.makeVodPlaybackModel,
                          makeMyListModel: env.makeMyListModel,
                          clearVodPositions: env.clearVodPositions,
                          settings: env.settings,
                          parental: env.parentalStore,
                          autoStart: autoStart,
                          onAdd: { adding = true })
    }
}
