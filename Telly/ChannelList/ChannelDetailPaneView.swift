import SwiftUI

/// The iPad split-view detail pane: the selected channel's identity (logo,
/// number, name, group, favourite), its EPG now/next, and a prominent Play
/// button that tunes through the caller's parental-gated path. A neutral
/// placeholder fills the pane until a channel is chosen. Pure presentation.
struct ChannelDetailPaneView: View {
    let channel: ChannelEntity?
    let nowNext: NowNext?
    let nowMs: Int
    let onPlay: (ChannelEntity) -> Void

    var body: some View {
        if let channel {
            content(channel).navigationTitle(channel.displayName)
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
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

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
