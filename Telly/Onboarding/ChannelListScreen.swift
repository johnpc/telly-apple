import SwiftUI

/// The post-onboarding channel list: a group-filter strip over the visible
/// channels, a long-press menu (favourite / lock / hide) and toolbar links to
/// the Guide, Search, History and the editors. A row opens the live player
/// unless a PIN-lock gates it (`+Parental`); logic lives in ``ChannelListModel``.
struct ChannelListScreen: View {
    @State var model: ChannelListModel
    let makeEngine: () -> VLCKitPlayerEngine
    let makeGuideGridModel: () -> GuideGridModel
    let makeCatchupModel: (CatchupRequest) -> CatchupPlaybackModel
    let makeHistoryModel: () -> HistoryListModel
    let makeSearchModel: () -> SearchModel
    let makeChannelEditModel: (String?) -> ChannelEditModel
    let makeVisibilityEditModel: () -> VisibilityEditModel
    let makeBackupModel: () -> SettingsBackupModel
    let makePlaylistsSettingsModel: () -> PlaylistsSettingsModel
    let makeVodBrowseModel: () -> VodBrowseModel
    let makeVodPlaybackModel: (String, @escaping () -> Void) -> VodPlaybackModel
    let makeMyListModel: () -> MyListModel
    let clearVodPositions: () -> Void
    let settings: SettingsStore
    let parental: ParentalStore
    let onAdd: () -> Void
    /// Drives the initial `model.start()`; DEBUG screenshots pass false to pin a phase.
    let autoStart: Bool
    @State var target: PlaybackTarget?
    @State var showSettings = false
    @State var challenge: ParentalChannelBox?
    @State var lockTarget: ParentalChannelBox?

    init(model: ChannelListModel, makeEngine: @escaping () -> VLCKitPlayerEngine,
         makeGuideGridModel: @escaping () -> GuideGridModel,
         makeCatchupModel: @escaping (CatchupRequest) -> CatchupPlaybackModel,
         makeHistoryModel: @escaping () -> HistoryListModel,
         makeSearchModel: @escaping () -> SearchModel,
         makeChannelEditModel: @escaping (String?) -> ChannelEditModel,
         makeVisibilityEditModel: @escaping () -> VisibilityEditModel,
         makeBackupModel: @escaping () -> SettingsBackupModel,
         makePlaylistsSettingsModel: @escaping () -> PlaylistsSettingsModel,
         makeVodBrowseModel: @escaping () -> VodBrowseModel,
         makeVodPlaybackModel: @escaping (String, @escaping () -> Void) -> VodPlaybackModel,
         makeMyListModel: @escaping () -> MyListModel,
         clearVodPositions: @escaping () -> Void,
         settings: SettingsStore,
         parental: ParentalStore,
         autoStart: Bool = true,
         onAdd: @escaping () -> Void) {
        _model = State(initialValue: model)
        self.autoStart = autoStart
        self.makeEngine = makeEngine
        self.makeGuideGridModel = makeGuideGridModel
        self.makeCatchupModel = makeCatchupModel
        self.makeHistoryModel = makeHistoryModel
        self.makeSearchModel = makeSearchModel
        self.makeChannelEditModel = makeChannelEditModel
        self.makeVisibilityEditModel = makeVisibilityEditModel
        self.makeBackupModel = makeBackupModel
        self.makePlaylistsSettingsModel = makePlaylistsSettingsModel
        self.makeVodBrowseModel = makeVodBrowseModel
        self.makeVodPlaybackModel = makeVodPlaybackModel
        self.makeMyListModel = makeMyListModel
        self.clearVodPositions = clearVodPositions
        self.settings = settings
        self.parental = parental
        self.onAdd = onAdd
    }

    var body: some View {
        NavigationStack {
            loadStateContent
            .navigationTitle("Channels")
            .toolbar { toolbarContent }
            #if !os(tvOS)
            // iPhone/iPad only: on tvOS an inline `.searchable` forces a full-screen
            // keyboard onto the home screen, so search is a dedicated toolbar item.
            .searchable(text: $model.query, prompt: "Search channels")
            .overlay {
                if !model.query.isEmpty && model.rows.isEmpty {
                    ContentUnavailableView.search(text: model.query)
                }
            }
            #endif
        }
        .task { if autoStart { await model.start() } }
        .fullScreenCover(item: $target) { target in
            PlaybackScreen(streamUrl: target.url, engine: makeEngine())
        }
        .sheet(item: $challenge) { challengeSheet($0.channel) }
        .sheet(item: $lockTarget) { lockSheet($0.channel) }
        .sheet(isPresented: $showSettings) {
            SettingsScreen(settings: settings, parental: parental,
                           backup: makeBackupModel(),
                           playlists: makePlaylistsSettingsModel(),
                           makeVisibilityEditModel: makeVisibilityEditModel,
                           clearVodPositions: clearVodPositions,
                           onClose: { showSettings = false })
        }
    }
}
