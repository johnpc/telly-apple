import SwiftUI

/// One My List row: the referenced channel (reusing ``ChannelListRowView``'s
/// number/name/favourite tile), the saved programme title — accent-tinted while
/// it is airing now — and the air-time stamp as a caption. Android shows the
/// title + time atop the channel; the plain channel row alone doesn't, so this
/// is a dedicated row wrapping it.
struct MyListRowView: View {
    let row: MyListRow

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ChannelListRowView(channel: row.channel)
            Text(row.entry.title)
                .font(.subheadline)
                .foregroundStyle(row.airing ? Color.accentColor : Color.primary)
            Text(row.airTimeText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
