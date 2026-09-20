import SwiftUI

/// The post-onboarding channel list: a group-filter strip over the visible
/// channels, a long-press menu (favourite / hide) and toolbar links to the
/// Guide, Search, History and the editors. A row opens the live player
/// (`+Row`); logic lives in ``ChannelListModel``.
struct ChannelListScreen: View {
    @State var model: ChannelListModel
    let makeEngine: () -> VLCKitPlayerEngine
    /// Shared live engine + guide-overlay state the live host reads (no reconnect).
    let liveEngineStore: LiveEngineStore
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
    /// The per-channel Assign-EPG picker factory the row menu's "Assign EPG"
    /// action presents (same picker the Settings EPG-assignment list vends).
    let makeAssignEpgModel: (ChannelEntity) -> AssignEpgModel
    let clearVodPositions: () -> UpdateOutcome
    /// The selected channel's now/next for the iPad detail pane; identity ({ nil })
    /// off the split path, so compact iPhone / tvOS / tests need not wire the EPG.
    let nowNext: (ChannelEntity) -> NowNext?
    /// Wall clock (ms) the detail pane's now/next progress reads; injected so the
    /// split render is deterministic. Unused on the compact/tvOS stack path.
    let nowMs: () -> Int
    let settings: SettingsStore
    let onAdd: () -> Void
    /// Drives the initial `model.start()`; DEBUG screenshots pass false to pin a phase.
    let autoStart: Bool
    #if !os(tvOS)
    /// Gates the iPad split layout: `.regular` earns the sidebar + detail split,
    /// `.compact` keeps the iPhone stack unchanged (see `ChannelListLayout`).
    @Environment(\.horizontalSizeClass) var sizeClass
    #endif
    @State var target: LiveStageTarget?
    /// The channel whose Assign-EPG picker sheet is open (raised by the row menu).
    @State var assignEpgTarget: AssignEpgTarget?
    @State var showSettings = false
    #if DEBUG
    /// The channel whose consolidated menu the screenshot proof pins open.
    @State var channelMenuProofTarget: ChannelEntity?
    #endif
    /// The sidebar's selected row, resolved into the detail pane's channel.
    @State var selectedChannelId: Int?
    #if os(tvOS)
    /// The channel the tvOS two-column home's remote focus rests on; drives the
    /// right-hand detail/preview pane (`+TvSplitView`) and the launch default focus.
    @FocusState var focusedChannelId: Int?
    #endif

    init(model: ChannelListModel, makeEngine: @escaping () -> VLCKitPlayerEngine,
         liveEngineStore: LiveEngineStore,
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
         makeAssignEpgModel: @escaping (ChannelEntity) -> AssignEpgModel,
         clearVodPositions: @escaping () -> UpdateOutcome,
         settings: SettingsStore,
         nowNext: @escaping (ChannelEntity) -> NowNext? = { _ in nil },
         nowMs: @escaping () -> Int = { 0 },
         autoStart: Bool = true,
         onAdd: @escaping () -> Void) {
        _model = State(initialValue: model)
        self.autoStart = autoStart
        self.makeEngine = makeEngine
        self.liveEngineStore = liveEngineStore
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
        self.makeAssignEpgModel = makeAssignEpgModel
        self.clearVodPositions = clearVodPositions
        self.settings = settings
        self.nowNext = nowNext
        self.nowMs = nowMs
        self.onAdd = onAdd
    }
}
