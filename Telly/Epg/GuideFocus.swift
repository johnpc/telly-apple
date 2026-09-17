import Foundation

/// The guide grid's single focus: the active row, the cell highlighted inside
/// it, and the time `anchorMs` held constant while moving vertically. The grid
/// renders no focusable cells (tvOS); this one value is what the header + every
/// row pan from. `anchorMs` is the wall-clock instant kept steady across UP/DOWN
/// moves — usually the focused cell's `startMs`, or "now" for the initial focus —
/// so a vertical move lands on the cell covering the same column on the new row.
/// `Int`, `GuideCell` and `Int` are `Equatable`, so the conformance is synthesised.
struct GuideFocus: Equatable {
    let rowIndex: Int
    let cell: GuideCell
    let anchorMs: Int
}
