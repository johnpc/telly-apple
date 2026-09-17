import SwiftUI

/// One channel-list row: sequential number, display name, optional group
/// caption, and a filled star when the channel is a favourite. Full-width
/// vertical layout with a trailing star, so it never clips horizontally on
/// compact iPhones.
struct ChannelListRowView: View {
    let channel: ChannelEntity

    var body: some View {
        HStack(spacing: 12) {
            Text("\(channel.number)")
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .frame(minWidth: 44, alignment: .trailing)
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
}
