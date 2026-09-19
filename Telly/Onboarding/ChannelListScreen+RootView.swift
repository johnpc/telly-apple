import SwiftUI

/// The channel list's platform-adaptive shell, split from `ChannelListScreen` to
/// keep both within the source-line budget. Compact iPhone and tvOS keep the
/// single stacked `NavigationStack` verbatim; iPad regular width routes to the
/// `NavigationSplitView` (`+SplitView`). The playback cover and the settings
/// sheet hang off the shared root so both layouts present them.
extension ChannelListScreen {
    var body: some View {
        layoutRoot
            .task { if autoStart { await model.start() } }
            .fullScreenCover(item: $target) { target in
                PlaybackScreen(streamUrl: target.url, engine: makeEngine())
            }
            .sheet(isPresented: $showSettings) { settingsSheet }
    }

    @ViewBuilder private var layoutRoot: some View {
        #if os(tvOS)
        stackBody
        #else
        if ChannelListLayout.usesSplit(sizeClass) { splitBody } else { stackBody }
        #endif
    }

    /// The single-column list: the iPhone/tvOS home, unchanged from before the
    /// iPad split landed. tvOS omits the inline `.searchable` (it would force a
    /// full-screen keyboard onto the home screen); search there is a toolbar item.
    var stackBody: some View {
        NavigationStack {
            loadStateContent
                .navigationTitle("Channels")
                .toolbar { toolbarContent }
                #if !os(tvOS)
                .searchable(text: $model.query, prompt: "Search channels")
                .overlay { searchEmptyOverlay }
                #endif
        }
    }

    #if !os(tvOS)
    @ViewBuilder var searchEmptyOverlay: some View {
        if !model.query.isEmpty && model.rows.isEmpty {
            ContentUnavailableView.search(text: model.query)
        }
    }
    #endif

    var settingsSheet: some View {
        SettingsScreen(settings: settings,
                       backup: makeBackupModel(),
                       playlists: makePlaylistsSettingsModel(),
                       makeVisibilityEditModel: makeVisibilityEditModel,
                       clearVodPositions: clearVodPositions,
                       onClose: { showSettings = false })
    }
}
