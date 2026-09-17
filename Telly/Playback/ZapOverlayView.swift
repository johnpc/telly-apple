import SwiftUI

/// The compact channel-change overlay shown while a just-zapped stream tunes: a
/// bottom scrim carrying the channel number, its group and display name. No EPG
/// now/next, logo or progress yet — those arrive with the info overlay (S4).
/// Renders nothing until a channel is tuned.
struct ZapOverlayView: View {
    let channel: ChannelEntity?

    var body: some View {
        if let channel {
            content(channel)
        }
    }

    private func content(_ channel: ChannelEntity) -> some View {
        VStack {
            Spacer()
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
            .foregroundStyle(.white)
            .padding(.horizontal, 48)
            .padding(.top, 44)
            .padding(.bottom, 44)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(scrim)
        }
        .ignoresSafeArea()
    }

    private var scrim: some View {
        LinearGradient(colors: [.black.opacity(0), .black.opacity(0.85)],
                       startPoint: .top, endPoint: .bottom)
    }
}
