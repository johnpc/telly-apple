import SwiftUI

/// The program info panel's channel identity row: the logo (when the source
/// carries one), the sequential channel number, and the display name. A compact
/// mirror of ``ChannelDetailHeaderView`` tuned for the panel's tighter layout.
struct ProgramInfoHeaderView: View {
    let channel: ChannelEntity

    var body: some View {
        HStack(spacing: 14) {
            logo
            VStack(alignment: .leading, spacing: 2) {
                Text("Channel \(channel.number)")
                    .font(.caption).monospacedDigit().foregroundStyle(.secondary)
                Text(channel.displayName)
                    .font(.headline).lineLimit(1)
            }
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder private var logo: some View {
        if let url = channel.source.logoUrl.flatMap(URL.init) {
            AsyncImage(url: url) { $0.resizable().scaledToFit() } placeholder: { Color.clear }
                .frame(width: 48, height: 48)
        }
    }
}
