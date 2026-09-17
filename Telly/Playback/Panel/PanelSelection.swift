import Foundation

/// The channel-panel D-pad selection: which column holds focus (groups vs rows)
/// and the selected index within each. Immutable transforms so navigation is
/// unit-tested without a view. Key-routing is a later slice — these transforms
/// are built and tested but not yet wired to ``PlaybackKeyPolicy``; the view
/// seeds the initial focus for a deterministic screenshot.
struct PanelSelection: Equatable {
    var groupIndex: Int
    var rowIndex: Int
    var inGroups: Bool

    /// Opens the panel focused on the playing channel's row (clamped into the
    /// row list) under the first group.
    static func initial(groups: Int, rows: Int, selectedRow: Int) -> PanelSelection {
        PanelSelection(groupIndex: clamp(0, count: groups),
                       rowIndex: clamp(selectedRow, count: rows),
                       inGroups: false)
    }

    /// Moves row focus down one, clamped to the last row.
    func movedDown(rowCount: Int) -> PanelSelection {
        with { $0.rowIndex = min(rowIndex + 1, max(rowCount - 1, 0)) }
    }

    /// Moves row focus up one, clamped to the first row.
    func movedUp() -> PanelSelection {
        with { $0.rowIndex = max(rowIndex - 1, 0) }
    }

    /// Shifts focus to the groups column.
    func focusGroups() -> PanelSelection { with { $0.inGroups = true } }

    /// Shifts focus to the rows column.
    func focusRows() -> PanelSelection { with { $0.inGroups = false } }

    private func with(_ mutate: (inout PanelSelection) -> Void) -> PanelSelection {
        var copy = self
        mutate(&copy)
        return copy
    }

    private static func clamp(_ index: Int, count: Int) -> Int {
        guard count > 0 else { return 0 }
        return min(max(index, 0), count - 1)
    }
}
