import SwiftUI

/// One fixed-height tile in the guide's left channel column: number, optional
/// logo and the channel name. The name marquees (via `MarqueeTextView`) while the
/// tile is `active` — its row is focused on tvOS, or the pointer hovers it on
/// iPadOS — and sits truncated otherwise. Pure rendering; height/width supplied.
struct GuideChannelTileView: View {
    let row: GuideRow
    let width: CGFloat
    let compact: Bool
    let focused: Bool
    #if !os(tvOS)
    @State private var hovering = false
    #endif

    private var active: Bool {
        #if os(tvOS)
        focused
        #else
        focused || hovering
        #endif
    }

    var body: some View {
        HStack(spacing: 8) {
            Text("\(row.displayNumber)")
                .monospacedDigit()
                .foregroundStyle(.secondary)
            if !compact { logo(row.channel.source.logoUrl) }
            MarqueeTextView(text: row.channel.displayName, active: active)
        }
        .padding(.horizontal, 10)
        .frame(width: width, height: GuideGeometry.rowHeight, alignment: .leading)
        .overlay(Divider(), alignment: .bottom)
        .tellyFocus(active, cornerRadius: 4)
        #if !os(tvOS)
        .onHover { hovering = $0 }
        #endif
    }

    @ViewBuilder private func logo(_ urlString: String?) -> some View {
        if let urlString, let url = URL(string: urlString) {
            AsyncImage(url: url) { $0.resizable().scaledToFit() } placeholder: { Color.clear }
                .frame(width: 32, height: 32)
        }
    }
}
