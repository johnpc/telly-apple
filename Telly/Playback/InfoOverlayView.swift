import SwiftUI

/// The TiviMate-style channel-info bar (`.info` / `.infoTransport`): the channel
/// identity + clock header over the now/next programme area, on the shared
/// ``BottomOverlayBar`` scrim. `expanded` distinguishes `.infoTransport` (true)
/// from `.info` (false); when expanded it carries the interactive
/// ``LiveTransportRow`` (play/pause + channel change) below the now/next bar.
/// Renders nothing until a channel is tuned.
struct InfoOverlayView: View {
    let channel: ChannelEntity?
    let nowNext: NowNext?
    let nowMs: Int
    let expanded: Bool
    var transportFocus: LiveTransportButton = .playPause
    var isPaused = false
    var onTransport: (LiveTransportButton) -> Void = { _ in }

    var body: some View {
        if let channel {
            BottomOverlayBar {
                VStack(alignment: .leading, spacing: 20) {
                    InfoChannelHeaderView(channel: channel, nowMs: nowMs)
                    InfoProgramView(nowNext: nowNext, nowMs: nowMs)
                    if expanded {
                        LiveTransportRow(focus: transportFocus, isPaused: isPaused,
                                         onTap: onTransport)
                    }
                }
            }
        }
    }
}
