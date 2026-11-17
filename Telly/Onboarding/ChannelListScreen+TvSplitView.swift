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
            VStack(spacing: 0) {
                tvRail
                HStack(alignment: .top, spacing: 0) {
                    tvChannelColumn.frame(width: 640)
                    tvDetailPane.frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Channels")
        }
    }

    /// The Apple TV action rail (TiviMate's rail idiom): the home's primary actions
    /// as icon pills in the app's own row under the title, LEFT-aligned over the
    /// group chips so pressing UP from any chip lands on the rail (the focus engine
    /// needs horizontal overlap), and carrying their titles to VoiceOver — neither
    /// of which the tvOS navigation bar offers (see `+Toolbar`).
    private var tvRail: some View {
        HStack(spacing: 24) {
            navigationItems
            Spacer()
        }
        .padding(.horizontal, 80)
        .padding(.vertical, 8)
    }

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
    }

    /// The channel the preview pane shows: the focused row, else the first row
    /// (so a freshly loaded list is never a blank pane) — the same pure selector
    /// the iPad detail uses, so both surfaces resolve identically.
    private var tvDetailChannel: ChannelEntity? {
        ChannelListLayout.selectedChannel(in: model.rows, id: focusedChannelId)
    }

    /// The preview pane. It deliberately sets no `navigationTitle` on tvOS
    /// (`ChannelDetailPaneView` suppresses it there), so the shared bar keeps
    /// its "Channels" title while the pane fills the
    /// wide right half of the 16:9 home.
    private var tvDetailPane: some View {
        ChannelDetailPaneView(channel: tvDetailChannel,
                              nowNext: tvDetailChannel.flatMap(nowNext),
                              nowMs: nowMs(),
                              onPlay: tapped)
    }
}
#endif
