import SwiftUI

/// The guide's scrolling programme pane: every channel's `GuideRowStripView`
/// stacked vertically with the `GuideNowLineView` overlaid across them, clipped
/// to the model's viewport so cells pan in lockstep with the header. Pure
/// rendering — placement/now-line maths live in the `Guide*` helpers.
struct GuideRowsPaneView: View {
    let model: GuideGridModel
    let compact: Bool
    let onActivate: (GuideCell, GuideRow) -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                ForEach(Array(model.rows.enumerated()), id: \.offset) { index, row in
                    GuideRowStripView(row: row, rowIndex: index, model: model,
                                      compact: compact) { onActivate($0, row) }
                }
            }
            GuideNowLineView(offset: model.nowLineOffset)
        }
        .frame(width: model.viewport, alignment: .topLeading)
        .clipped()
    }
}
