import SwiftUI

/// One row in the Manage-Favorites / Manage-Visibility editors: a leading
/// favourite star, the sequential number, and the display name. Dimmed when the
/// channel is hidden. Full-width so it never clips on compact iPhones.
struct ChannelEditRowView: View {
    let channel: ChannelEntity

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: channel.flags.favorite ? "star.fill" : "star")
                .foregroundStyle(channel.flags.favorite ? .yellow : .secondary)
            Text("\(channel.number)").monospacedDigit().foregroundStyle(.secondary)
            Text(channel.displayName)
            Spacer(minLength: 0)
        }
        .opacity(channel.flags.hidden ? 0.4 : 1)
    }
}
