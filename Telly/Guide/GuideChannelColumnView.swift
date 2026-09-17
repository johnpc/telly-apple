import SwiftUI

/// The guide's fixed left column: one fixed-height tile per channel row showing
/// its number, name and (when available) logo, aligned to the programme rows'
/// vertical scroll. Width is supplied by the screen (narrower when compact) and
/// row height comes from `GuideGeometry`. Pure rendering — no layout maths here.
struct GuideChannelColumnView: View {
    let rows: [GuideRow]
    let width: CGFloat
    let compact: Bool

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                tile(row)
            }
        }
        .frame(width: width)
    }

    private func tile(_ row: GuideRow) -> some View {
        HStack(spacing: 8) {
            Text("\(row.displayNumber)")
                .monospacedDigit()
                .foregroundStyle(.secondary)
            if !compact { logo(row.channel.source.logoUrl) }
            Text(row.channel.displayName).lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .frame(width: width, height: GuideGeometry.rowHeight, alignment: .leading)
        .overlay(Divider(), alignment: .bottom)
    }

    @ViewBuilder private func logo(_ urlString: String?) -> some View {
        if let urlString, let url = URL(string: urlString) {
            AsyncImage(url: url) { $0.resizable().scaledToFit() } placeholder: { Color.clear }
                .frame(width: 32, height: 32)
        }
    }
}
