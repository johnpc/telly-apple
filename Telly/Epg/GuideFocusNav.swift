import Foundation

/// Pure focus-navigation maths for the guide grid: the core horizontal/vertical
/// focus transforms that the (deferred) pan engine and the tvOS focus anchor
/// compose from. Every function is total and View-free, so the whole set is
/// unit-testable headlessly. Cells within a row are contiguous, sorted by
/// `startMs`, and tile the materialised span (see `GuideCellsBuilder`).
enum GuideFocusNav {
    /// The next cell to the right of `focused`, or nil when it is already the
    /// last cell in the row.
    static func rightOf(cells: [GuideCell], focused: GuideCell) -> GuideCell? {
        guard let index = cells.firstIndex(of: focused), index + 1 < cells.count else { return nil }
        return cells[index + 1]
    }

    /// The previous cell to the left of `focused`, or nil at the left edge. The
    /// left edge is either `focused` being the first cell, or the previous cell
    /// beginning before `windowStartMs` (plain moves never pan left of "now").
    /// A nil result signals the caller to open the groups column / hold.
    static func leftOf(cells: [GuideCell], focused: GuideCell, windowStartMs: Int) -> GuideCell? {
        guard let index = cells.firstIndex(of: focused), index > 0 else { return nil }
        let previous = cells[index - 1]
        guard previous.startMs >= windowStartMs else { return nil }
        return previous
    }

    /// The cell whose half-open range contains `anchorMs`, else the nearest edge
    /// cell: the strip tiles its span contiguously, so a miss means the anchor is
    /// either before the strip (clamp to the first cell) or at/after its end
    /// (clamp to the last cell). Nil only when the strip is empty.
    static func cellAt(cells: [GuideCell], anchorMs: Int) -> GuideCell? {
        guard let first = cells.first, let last = cells.last else { return nil }
        if let hit = cells.first(where: { $0.contains(anchorMs) }) { return hit }
        return anchorMs < first.startMs ? first : last
    }

    /// Initial focus on row 0's cell covering `nowMs`, anchored at `nowMs`. Nil
    /// when there are no rows (or row 0 has no cells).
    static func initialFocus(rows: [GuideRow], nowMs: Int) -> GuideFocus? {
        guard let firstRow = rows.first,
              let cell = cellAt(cells: firstRow.cells, anchorMs: nowMs) else { return nil }
        return GuideFocus(rowIndex: 0, cell: cell, anchorMs: nowMs)
    }

    /// Re-derives a valid focus after the rows change: keeps the same `rowIndex`
    /// (clamped into range as rows grow/shrink) and re-picks the cell covering
    /// `current.anchorMs` on that row, keeping the vertical anchor stable. Falls
    /// back to `initialFocus` when `current` is nil; nil when there are no rows.
    static func resolve(rows: [GuideRow], nowMs: Int, current: GuideFocus?) -> GuideFocus? {
        guard let current else { return initialFocus(rows: rows, nowMs: nowMs) }
        guard !rows.isEmpty else { return nil }
        let rowIndex = min(max(current.rowIndex, 0), rows.count - 1)
        guard let cell = cellAt(cells: rows[rowIndex].cells, anchorMs: current.anchorMs) else { return nil }
        return GuideFocus(rowIndex: rowIndex, cell: cell, anchorMs: current.anchorMs)
    }
}
