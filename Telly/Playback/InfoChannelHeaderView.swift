import SwiftUI

/// The channel-identity row of the info overlay: the big channel number, an
/// optional logo, the display name with its group, and the wall clock pinned
/// top-right (TiviMate style). Pure presentation — all formatting lives in
/// ``InfoOverlayText``; this view holds no logic.
struct InfoChannelHeaderView: View {
    let channel: ChannelEntity
    let nowMs: Int

    var body: some View {
        HStack(alignment: .center, spacing: 24) {
            Text("\(channel.number)")
                .font(.system(size: 52, weight: .heavy, design: .rounded))
                .monospacedDigit()
            logo
            VStack(alignment: .leading, spacing: 4) {
                Text(channel.displayName)
                    .font(.title).fontWeight(.bold)
                    .lineLimit(1).truncationMode(.tail)
                if let group = channel.source.groupTitle, !group.isEmpty {
                    Text(group.uppercased())
                        .font(.subheadline).fontWeight(.medium)
                        .foregroundStyle(.white.opacity(0.65))
                        .lineLimit(1).truncationMode(.tail)
                }
            }
            Spacer(minLength: 12)
            Text(InfoOverlayText.clock(nowMs: nowMs))
                .font(.title2).fontWeight(.semibold).monospacedDigit()
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(1).fixedSize().layoutPriority(1)
        }
    }

    @ViewBuilder private var logo: some View {
        if let url = channel.source.logoUrl.flatMap(URL.init) {
            AsyncImage(url: url) { $0.resizable().scaledToFit() }
                placeholder: { Color.clear }
                .frame(width: 64, height: 64)
        }
    }
}
