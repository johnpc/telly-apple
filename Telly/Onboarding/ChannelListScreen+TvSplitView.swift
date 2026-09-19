import SwiftUI
#if os(tvOS)

/// The tvOS two-column home: the channel list on the left, a detail/preview pane
/// on the right that follows the remote's focused row — logo/number/name/group,
/// EPG now/next + progress, and a Play button. This fills the 16:9 canvas the
/// single stretched column left ~70% black, mirroring how the iPad `splitBody`
/// uses its width. iPhone-compact `stackBody` and iPad `splitBody` stay unchanged.
/// The detail follows focus (not a tap-selection) so browsing with the remote
/// updates the preview, resolving the channel via the shared `ChannelListLayout`
/// selector; `.defaultFocus` lands the launch focus on the first row, not the gear.
extension ChannelListScreen {
    var tvBody: some View {
        NavigationStack {
            HStack(alignment: .top, spacing: 0) {
                tvChannelColumn.frame(width: 640)
                tvDetailPane.frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    // The title and toolbar hang off the list content (as the single-column
    // `stackBody` does), not the wrapping `HStack`: on tvOS that keeps the bar
    // space-constrained so its action items collapse to icon-only pills. Hosting
    // them on the full-width `HStack` instead lets the bar sprawl and render the
    // items with washed-out, truncated titles ("Se…gs").
    private var tvChannelColumn: some View {
        channelLoadScaffold {
            VStack(spacing: 0) {
                groupPicker
                List(model.rows, id: \.id) { channel in
                    row(channel).focused($focusedChannelId, equals: channel.id)
                }
                .defaultFocus($focusedChannelId, model.rows.first?.id)
            }
        }
        .navigationTitle("Channels")
        .toolbar { toolbarContent }
    }

    /// The channel the preview pane shows: the focused row, else the first row
    /// (so a freshly loaded list is never a blank pane) — the same pure selector
    /// the iPad detail uses, so both surfaces resolve identically.
    private var tvDetailChannel: ChannelEntity? {
        ChannelListLayout.selectedChannel(in: model.rows, id: focusedChannelId)
    }

    /// The preview pane. It deliberately sets no `navigationTitle` on tvOS
    /// (`ChannelDetailPaneView` suppresses it there), so the shared bar keeps
    /// its "Channels" title and un-truncated toolbar while the pane fills the
    /// wide right half of the 16:9 home.
    private var tvDetailPane: some View {
        ChannelDetailPaneView(channel: tvDetailChannel,
                              nowNext: tvDetailChannel.flatMap(nowNext),
                              nowMs: nowMs(),
                              onPlay: tapped)
    }
}
#endif
