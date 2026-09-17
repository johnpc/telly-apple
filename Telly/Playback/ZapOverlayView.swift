import SwiftUI

/// The compact channel-change overlay shown while a just-zapped stream tunes:
/// the channel number, its group and display name over the shared
/// ``BottomOverlayBar`` scrim. No EPG now/next, logo or progress — those live
/// in the richer ``InfoOverlayView``. Renders nothing until a channel is tuned.
struct ZapOverlayView: View {
    let channel: ChannelEntity?

    var body: some View {
        if let channel {
            BottomOverlayBar {
                HStack(alignment: .firstTextBaseline, spacing: 20) {
                    Text("\(channel.number)")
                        .font(.system(size: 46, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    VStack(alignment: .leading, spacing: 6) {
                        if let group = channel.source.groupTitle, !group.isEmpty {
                            Text(group.uppercased())
                                .font(.caption).fontWeight(.semibold)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        Text(channel.displayName)
                            .font(.title2).fontWeight(.semibold)
                    }
                    Spacer()
                }
            }
        }
    }
}
