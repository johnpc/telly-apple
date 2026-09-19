import SwiftUI

/// The channel-row wiring for ``ChannelListScreen``, split out to keep the screen
/// within the source-line budget (mirrors the `+Toolbar` split). Holds the
/// channel row (with the consolidated ``channelMenu(_:model:assignTarget:)``) and
/// the tap that opens the live player. Logic lives in ``ChannelListModel``.
extension ChannelListScreen {
    @ViewBuilder func row(_ channel: ChannelEntity) -> some View {
        Button { tapped(channel) } label: { ChannelListRowView(channel: channel) }
            #if os(tvOS)
            .buttonStyle(.plain)
            #else
            .buttonStyle(TellyPressButtonStyle())
            #endif
            .channelMenu(channel, model: model, assignTarget: $assignEpgTarget)
    }

    /// Tune a channel: set the playback target so the fullscreen cover opens. The
    /// iPad detail pane's Play button routes here too.
    func tapped(_ channel: ChannelEntity) {
        TellyHaptics.selection()
        target = PlaybackTarget(id: channel.id, url: channel.source.streamUrl)
    }
}
