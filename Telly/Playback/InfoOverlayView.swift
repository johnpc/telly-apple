import SwiftUI

/// The TiviMate-style channel-info bar (`.info` / `.infoTransport`): the channel
/// identity + clock header over the now/next programme area, on the shared
/// ``BottomOverlayBar`` scrim. `expanded` distinguishes `.infoTransport` (true)
/// from `.info` (false); its transport row is a thin placeholder in this slice
/// (S5 owns the real controls). Renders nothing until a channel is tuned.
struct InfoOverlayView: View {
    let channel: ChannelEntity?
    let nowNext: NowNext?
    let nowMs: Int
    let expanded: Bool

    var body: some View {
        if let channel {
            BottomOverlayBar {
                VStack(alignment: .leading, spacing: 20) {
                    InfoChannelHeaderView(channel: channel, nowMs: nowMs)
                    InfoProgramView(nowNext: nowNext, nowMs: nowMs)
                    if expanded {
                        Text("Transport controls arrive in S5")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
            }
        }
    }
}
