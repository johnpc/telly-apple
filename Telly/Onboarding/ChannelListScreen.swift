import SwiftUI

/// The post-onboarding channel list: a scrollable group-filter strip over the
/// visible channels, each row showing a favourite star. A long-press context
/// menu adds to / removes from Favorites, locks / unlocks (PIN) or hides a
/// channel; toolbar links reach the Guide and the Manage-Favorites / Manage-
/// Visibility editors. Selecting a row opens the live player — unless the channel
/// is PIN-locked, when a challenge sheet gates the tune (see `+Parental`). Pure
/// presentation — logic lives in ``ChannelListModel`` / ``ParentalStore``.
struct ChannelListScreen: View {
    @State var model: ChannelListModel
    let makeEngine: () -> VLCKitPlayerEngine
    let makeGuideGridModel: () -> GuideGridModel
    let makeCatchupModel: (CatchupRequest) -> CatchupPlaybackModel
    let makeHistoryModel: () -> HistoryListModel
    let makeChannelEditModel: (String?) -> ChannelEditModel
    let makeVisibilityEditModel: () -> VisibilityEditModel
    let makeBackupModel: () -> SettingsBackupModel
    let makePlaylistsSettingsModel: () -> PlaylistsSettingsModel
    let settings: SettingsStore
    let parental: ParentalStore
    let onAdd: () -> Void
    @State var target: PlaybackTarget?
    @State var showSettings = false
    @State var challenge: ParentalChannelBox?
    @State var lockTarget: ParentalChannelBox?

    init(model: ChannelListModel, makeEngine: @escaping () -> VLCKitPlayerEngine,
         makeGuideGridModel: @escaping () -> GuideGridModel,
         makeCatchupModel: @escaping (CatchupRequest) -> CatchupPlaybackModel,
         makeHistoryModel: @escaping () -> HistoryListModel,
         makeChannelEditModel: @escaping (String?) -> ChannelEditModel,
         makeVisibilityEditModel: @escaping () -> VisibilityEditModel,
         makeBackupModel: @escaping () -> SettingsBackupModel,
         makePlaylistsSettingsModel: @escaping () -> PlaylistsSettingsModel,
         settings: SettingsStore,
         parental: ParentalStore,
         onAdd: @escaping () -> Void) {
        _model = State(initialValue: model)
        self.makeEngine = makeEngine
        self.makeGuideGridModel = makeGuideGridModel
        self.makeCatchupModel = makeCatchupModel
        self.makeHistoryModel = makeHistoryModel
        self.makeChannelEditModel = makeChannelEditModel
        self.makeVisibilityEditModel = makeVisibilityEditModel
        self.makeBackupModel = makeBackupModel
        self.makePlaylistsSettingsModel = makePlaylistsSettingsModel
        self.settings = settings
        self.parental = parental
        self.onAdd = onAdd
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ChannelGroupPickerView(groups: model.groups, selected: model.selectedGroup,
                                       onSelect: model.select)
                List(model.rows, id: \.id) { channel in row(channel) }
            }
            .navigationTitle("Channels")
            .toolbar { toolbarContent }
            .searchable(text: $model.query, prompt: "Search channels")
            .overlay { searchEmptyState }
        }
        .task { model.load() }
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
                           onClose: { showSettings = false })
        }
    }

    /// Shown when a search yields nothing so the empty List isn't just blank.
    @ViewBuilder private var searchEmptyState: some View {
        if !model.query.isEmpty && model.rows.isEmpty {
            ContentUnavailableView.search(text: model.query)
        }
    }
}

/// Identifies the channel currently being played (drives the fullscreen cover).
struct PlaybackTarget: Identifiable {
    let id: Int
    let url: String
}

/// Boxes a channel awaiting a parental-PIN sheet (challenge-to-tune or lock/
/// unlock confirmation), giving `.sheet(item:)` the `Identifiable` it needs
/// without making ``ChannelEntity`` itself identifiable.
struct ParentalChannelBox: Identifiable {
    let channel: ChannelEntity
    var id: Int { channel.id }
}
