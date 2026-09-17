import SwiftUI

/// The channel-panel overlay layer for ``LivePlaybackScreen``: renders the
/// in-playback panel (channels + group column) when the `.panel` overlay is up,
/// forwarding the screen's `customGroups` so the group column lists them after
/// the playlist groups. Kept in its own `*View.swift` file so the screen's ZStack
/// just composes it, matching the other overlay ViewBuilders.
extension LivePlaybackScreen {
    @ViewBuilder var panelOverlay: some View {
        if case .panel = model.overlay {
            ChannelPanelView(channels: model.channels, current: model.current,
                             nowNext: model.nowNext, nowMs: model.now(),
                             customGroups: customGroups)
        }
    }
}
