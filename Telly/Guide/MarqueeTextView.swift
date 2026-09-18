import SwiftUI
import UIKit

/// A single line of text that scrolls (marquees) only while `active` and only
/// when it is too wide for the space it is given; otherwise it renders plainly,
/// tail-truncated, with no animation or layout jump. Reduce Motion forces the
/// static truncated form. Offset timing comes from the pure `MarqueeMetrics`.
/// The available width is read from a `GeometryReader` (and used to hard-clip the
/// sliding line to the column), while the text's full width is measured from
/// string metrics using the very font it renders with — a hidden SwiftUI probe
/// gets clamped to the container, so it can never detect the overflow.
struct MarqueeTextView: View {
    let text: String
    let active: Bool
    var uiFont: UIFont = .preferredFont(forTextStyle: .body)

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var startDate = Date()

    /// The text's full, untruncated width, independent of the space it is given.
    private var textWidth: CGFloat {
        (text as NSString).size(withAttributes: [.font: uiFont]).width
    }

    private func scrolling(container: CGFloat) -> Bool {
        active && !reduceMotion && MarqueeMetrics.overflows(
            textWidth: textWidth, containerWidth: container)
    }

    var body: some View {
        GeometryReader { geo in
            content(container: geo.size.width)
                .frame(width: geo.size.width, height: geo.size.height, alignment: .leading)
                .clipped()
        }
        .frame(height: uiFont.lineHeight)
        .onChange(of: active) { _, now in if now { startDate = Date() } }
    }

    @ViewBuilder private func content(container: CGFloat) -> some View {
        if scrolling(container: container) {
            TimelineView(.animation) { ctx in
                label
                    .fixedSize()
                    .offset(x: MarqueeMetrics.offset(textWidth: textWidth,
                                                     containerWidth: container,
                                                     elapsed: ctx.date.timeIntervalSince(startDate)))
            }
        } else {
            label.lineLimit(1).truncationMode(.tail)
        }
    }

    private var label: some View { Text(text).font(Font(uiFont)).lineLimit(1) }
}
