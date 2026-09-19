import SwiftUI

/// One channel-list row: sequential number, the channel logo (when the source
/// carries one), display name, optional group caption, and a filled star when
/// the channel is a favourite. Full-width vertical layout with a trailing star,
/// so it never clips horizontally on compact iPhones.
struct ChannelListRowView: View {
    let channel: ChannelEntity

    var body: some View {
        HStack(spacing: 12) {
            Text("\(channel.number)")
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .frame(minWidth: 44, alignment: .trailing)
            logo
            VStack(alignment: .leading, spacing: 2) {
                Text(channel.displayName)
                if let group = channel.source.groupTitle, !group.isEmpty {
                    Text(group).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
            if channel.flags.favorite {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                    .accessibilityLabel("Favorite")
            }
        }
    }

    /// The channel logo — the same async-image path the guide's channel column
    /// uses (`GuideChannelTileView`). Absent logos take no space, so the row
    /// falls back to the number + name as before.
    @ViewBuilder private var logo: some View {
        if let url = channel.source.logoUrl.flatMap(URL.init) {
            AsyncImage(url: url) { $0.resizable().scaledToFit() } placeholder: { Color.clear }
                .frame(width: 40, height: 40)
        }
    }
}
