import SwiftUI

/// The channel detail pane's identity block: the logo (when the source carries
/// one), the sequential number, the display name, its group, and a favourite
/// badge. Pure presentation for the iPad split detail (`ChannelDetailPaneView`).
struct ChannelDetailHeaderView: View {
    let channel: ChannelEntity

    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            logo
            VStack(alignment: .leading, spacing: 8) {
                Text("Channel \(channel.number)")
                    .font(.subheadline).monospacedDigit().foregroundStyle(.secondary)
                Text(channel.displayName)
                    .font(.largeTitle).fontWeight(.bold)
                if let group = channel.source.groupTitle, !group.isEmpty {
                    Text(group).font(.headline).foregroundStyle(.secondary)
                }
                if channel.flags.favorite {
                    Label("Favorite", systemImage: "star.fill")
                        .font(.subheadline).foregroundStyle(.yellow)
                }
            }
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder private var logo: some View {
        if let url = channel.source.logoUrl.flatMap(URL.init) {
            AsyncImage(url: url) { $0.resizable().scaledToFit() } placeholder: { Color.clear }
                .frame(width: 88, height: 88)
        }
    }
}
