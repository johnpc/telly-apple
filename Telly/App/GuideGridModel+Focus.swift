import Foundation

/// tvOS D-pad focus navigation for the guide grid. Each move delegates to the
/// pure `GuideFocusNav` transforms, then commits the result through the model's
/// `applyFocus` (which pans the scroll so the new cell stays on-screen and
/// re-materialises). RIGHT/LEFT re-anchor to the stepped cell's start; UP/DOWN
/// hold the current time anchor so the focus lands on the same column of the new
/// row. A nil transform (row edge / left of "now") holds focus unchanged.
extension GuideGridModel {
    /// Steps focus one cell right, panning at the right viewport edge.
    func focusRight() {
        guard let focus, rows.indices.contains(focus.rowIndex),
              let next = GuideFocusNav.rightOf(
                cells: rows[focus.rowIndex].cells, focused: focus.cell) else { return }
        applyFocus(rowIndex: focus.rowIndex, cell: next, anchorMs: next.startMs)
    }

    /// Steps focus one cell left; holds at the left edge (never pans left of now).
    func focusLeft() {
        guard let focus, rows.indices.contains(focus.rowIndex),
              let prev = GuideFocusNav.leftOf(
                cells: rows[focus.rowIndex].cells, focused: focus.cell,
                windowStartMs: originMs) else { return }
        applyFocus(rowIndex: focus.rowIndex, cell: prev, anchorMs: prev.startMs)
    }

    /// Moves focus up one row, keeping the current time anchor.
    func focusUp() { moveRow(by: -1) }

    /// Moves focus down one row, keeping the current time anchor.
    func focusDown() { moveRow(by: 1) }

    private func moveRow(by delta: Int) {
        guard let focus else { return }
        let target = focus.rowIndex + delta
        guard rows.indices.contains(target),
              let cell = GuideFocusNav.cellAt(
                cells: rows[target].cells, anchorMs: focus.anchorMs) else { return }
        applyFocus(rowIndex: target, cell: cell, anchorMs: focus.anchorMs)
    }
}
