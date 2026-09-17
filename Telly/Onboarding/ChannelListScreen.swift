import SwiftUI

/// The post-onboarding channel list: a scrollable group-filter strip over the
/// visible channels, each row showing a favourite star. A long-press context
/// menu adds to / removes from Favorites or hides a channel; toolbar links reach
/// the Guide and the Manage-Favorites / Manage-Visibility editors. Selecting a
/// row opens the live player. Pure presentation — logic lives in
/// ``ChannelListModel``.
struct ChannelListScreen: View {
    @State private var model: ChannelListModel
    let makeEngine: () -> VLCKitPlayerEngine
    let makeGuideGridModel: () -> GuideGridModel
    let makeChannelEditModel: (String?) -> ChannelEditModel
    let makeVisibilityEditModel: () -> VisibilityEditModel
    let settings: SettingsStore
    let onAdd: () -> Void
    @State private var target: PlaybackTarget?
    @State var showSettings = false

    init(model: ChannelListModel, makeEngine: @escaping () -> VLCKitPlayerEngine,
         makeGuideGridModel: @escaping () -> GuideGridModel,
         makeChannelEditModel: @escaping (String?) -> ChannelEditModel,
         makeVisibilityEditModel: @escaping () -> VisibilityEditModel,
         settings: SettingsStore,
         onAdd: @escaping () -> Void) {
        _model = State(initialValue: model)
        self.makeEngine = makeEngine
        self.makeGuideGridModel = makeGuideGridModel
        self.makeChannelEditModel = makeChannelEditModel
        self.makeVisibilityEditModel = makeVisibilityEditModel
        self.settings = settings
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
        .sheet(isPresented: $showSettings) {
            SettingsScreen(settings: settings, onClose: { showSettings = false })
        }
    }

    /// Shown when a search yields nothing so the empty List isn't just blank.
    @ViewBuilder private var searchEmptyState: some View {
        if !model.query.isEmpty && model.rows.isEmpty {
            ContentUnavailableView.search(text: model.query)
        }
    }

    @ViewBuilder private func row(_ channel: ChannelEntity) -> some View {
        Button {
            target = PlaybackTarget(id: channel.id, url: channel.source.streamUrl)
        } label: {
            ChannelListRowView(channel: channel)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(channel.flags.favorite ? "Remove Favorite" : "Add to Favorites") {
                model.toggleFavorite(channel)
            }
            Button("Hide channel", role: .destructive) { model.hide(channel) }
        }
    }
}

/// Identifies the channel currently being played (drives the fullscreen cover).
private struct PlaybackTarget: Identifiable {
    let id: Int
    let url: String
}
