import SwiftUI

/// One channel's programme strip: each `GuideCell` placed by
/// `GuideCellLayout.place` at its on-screen offset/width for the current scroll,
/// off-viewport cells skipped. Shows the programme title (or "No information"
/// for a filler); on tvOS the model's focused cell wears a focus ring. Pure
/// rendering — placement maths lives in `GuideCellLayout`.
struct GuideRowStripView: View {
    let row: GuideRow
    let rowIndex: Int
    let model: GuideGridModel
    let compact: Bool
    let onTap: (GuideCell) -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(row.cells.enumerated()), id: \.offset) { _, cell in
                if let placement = GuideCellLayout.place(
                    cell, originMs: model.originMs, scrollX: model.scrollX, viewport: model.viewport) {
                    tile(cell, placement: placement)
                }
            }
        }
        .frame(height: GuideGeometry.rowHeight)
    }

    private func tile(_ cell: GuideCell, placement: GuideCellPlacement) -> some View {
        Text(cell.program?.details.title ?? "No information")
            .font(compact ? .caption : .body)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .frame(width: placement.width, height: GuideGeometry.rowHeight, alignment: .leading)
            .background(cell.hasInfo ? Color.gray.opacity(0.25) : Color.clear)
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(.white.opacity(0.15)))
            .tellyFocus(isFocused(cell), cornerRadius: 4)
            .offset(x: placement.offset)
            .onTapGesture { onTap(cell) }
    }

    /// The app's model-driven focus for this cell (tvOS D-pad); nil elsewhere, so
    /// the shared treatment stays dormant on platforms without guide focus.
    private func isFocused(_ cell: GuideCell) -> Bool {
        model.focus?.rowIndex == rowIndex && model.focus?.cell == cell
    }
}
