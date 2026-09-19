import SwiftUI
#if !os(tvOS)

/// The iPad regular-width layout: a `NavigationSplitView` whose sidebar is the
/// group strip + a selectable channel list, and whose detail pane shows the
/// selected channel's now/next and a Play button. This fills the large canvas
/// the stretched single column wasted, mirroring how TiviMate uses the width.
/// Selecting a row drives the detail; Play tunes through the same parental-gated
/// `tapped` path a compact tap uses, so playback behaviour is preserved.
extension ChannelListScreen {
    var splitBody: some View {
        NavigationSplitView {
            sidebar
                .navigationTitle("Channels")
                .toolbar { toolbarContent }
                .searchable(text: $model.query, prompt: "Search channels")
                .overlay { searchEmptyOverlay }
        } detail: {
            NavigationStack { detailPane }
        }
    }

    private var sidebar: some View {
        channelLoadScaffold {
            VStack(spacing: 0) {
                groupPicker
                List(model.rows, id: \.id, selection: $selectedChannelId) { channel in
                    sidebarRow(channel).tag(channel.id)
                }
            }
        }
    }

    /// A sidebar row: plain content so the `List(selection:)` tap drives the
    /// detail (rather than a Button swallowing it), with the same long-press
    /// favourite / lock / hide menu the stack row carries.
    @ViewBuilder private func sidebarRow(_ channel: ChannelEntity) -> some View {
        ChannelListRowView(channel: channel)
            .contentShape(Rectangle())
            .contextMenu { rowContextMenu(channel) }
    }

    private var detailChannel: ChannelEntity? {
        ChannelListLayout.selectedChannel(in: model.rows, id: selectedChannelId)
    }

    @ViewBuilder private var detailPane: some View {
        ChannelDetailPaneView(channel: detailChannel,
                              nowNext: detailChannel.flatMap(nowNext),
                              nowMs: nowMs(),
                              onPlay: tapped)
    }
}
#endif
