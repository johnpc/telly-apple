import SwiftUI

/// The guide's fixed left column: one fixed-height tile per channel row (see
/// `GuideChannelTileView`) showing its number, name and (when available) logo,
/// aligned to the programme rows' vertical scroll. Width is supplied by the
/// screen (narrower when compact) and row height comes from `GuideGeometry`.
/// `activeRowIndex` is the tvOS-focused row (nil elsewhere) whose name marquees.
struct GuideChannelColumnView: View {
    let rows: [GuideRow]
    let width: CGFloat
    let compact: Bool
    let activeRowIndex: Int?

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                GuideChannelTileView(row: row, width: width, compact: compact,
                                     focused: index == activeRowIndex)
            }
        }
        .frame(width: width)
    }
}
