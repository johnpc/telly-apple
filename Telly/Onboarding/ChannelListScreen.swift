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
    let onAdd: () -> Void
    @State private var target: PlaybackTarget?

    init(model: ChannelListModel, makeEngine: @escaping () -> VLCKitPlayerEngine,
         makeGuideGridModel: @escaping () -> GuideGridModel,
         makeChannelEditModel: @escaping (String?) -> ChannelEditModel,
         makeVisibilityEditModel: @escaping () -> VisibilityEditModel,
         onAdd: @escaping () -> Void) {
        _model = State(initialValue: model)
        self.makeEngine = makeEngine
        self.makeGuideGridModel = makeGuideGridModel
        self.makeChannelEditModel = makeChannelEditModel
        self.makeVisibilityEditModel = makeVisibilityEditModel
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
        }
        .task { model.load() }
        .fullScreenCover(item: $target) { target in
            PlaybackScreen(streamUrl: target.url, engine: makeEngine())
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

    @ToolbarContentBuilder private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            NavigationLink("Guide") {
                GuideGridScreen(model: makeGuideGridModel(), makeEngine: makeEngine)
            }
        }
        ToolbarItem(placement: .primaryAction) {
            NavigationLink("Favorites") { ManageFavoritesScreen(model: makeChannelEditModel(nil)) }
        }
        ToolbarItem(placement: .primaryAction) {
            NavigationLink("Visibility") { ManageVisibilityScreen(model: makeVisibilityEditModel()) }
        }
        ToolbarItem(placement: .primaryAction) { Button("Add", action: onAdd) }
    }
}

/// Identifies the channel currently being played (drives the fullscreen cover).
private struct PlaybackTarget: Identifiable {
    let id: Int
    let url: String
}
