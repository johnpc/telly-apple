import SwiftUI

/// The iPad split-view detail pane: the selected channel's identity (logo,
/// number, name, group, favourite), its EPG now/next, and a prominent Play
/// button that tunes through the caller's tune path. A neutral
/// placeholder fills the pane until a channel is chosen. Pure presentation.
struct ChannelDetailPaneView: View {
    let channel: ChannelEntity?
    let nowNext: NowNext?
    let nowMs: Int
    let onPlay: (ChannelEntity) -> Void

    var body: some View {
        if let channel {
            // tvOS omits the nav title: this pane is the right half of a shared
            // `NavigationStack` whose bar already reads "Channels", and the
            // channel's name would otherwise leak up and truncate that bar.
            // The header inside already names the channel. iPad keeps it as the
            // detail column's own title.
            #if os(tvOS)
            content(channel)
            #else
            content(channel).navigationTitle(channel.displayName)
            #endif
        } else {
            ContentUnavailableView("Select a channel", systemImage: "tv",
                                   description: Text("Choose a channel to see what's on."))
        }
    }

    private func content(_ channel: ChannelEntity) -> some View {
        VStack(alignment: .leading, spacing: 28) {
            ChannelDetailHeaderView(channel: channel)
            ChannelDetailProgramView(nowNext: nowNext, nowMs: nowMs)
            playButton(channel)
            Spacer(minLength: 0)
        }
        .padding(Self.contentPadding)
        // Cap the reading column and centre it so a 13" landscape pane reads as
        // a balanced block instead of clinging to the left with one wide, empty
        // right gutter. Portrait / narrower panes are below the cap so they fill.
        // tvOS lifts the cap: its pane is the wide right half of the 16:9 home
        // (`+TvSplitView`), where a 720pt block would cling to the left instead.
        .frame(maxWidth: Self.readingWidth, alignment: .topLeading)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    #if os(tvOS)
    private static let readingWidth: CGFloat = .infinity
    private static let contentPadding: CGFloat = 48
    #else
    private static let readingWidth: CGFloat = 720
    private static let contentPadding: CGFloat = 32
    #endif

    private func playButton(_ channel: ChannelEntity) -> some View {
        Button { TellyHaptics.selection(); onPlay(channel) } label: {
            Label("Play", systemImage: "play.fill")
                .font(.title3.weight(.semibold))
                .frame(maxWidth: 320)
                .padding(.vertical, 6)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }
}
