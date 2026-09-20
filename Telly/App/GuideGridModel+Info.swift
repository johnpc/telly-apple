import Foundation

/// The guide cell → program info panel decision. Any info-carrying cell (airing,
/// catch-up-eligible, or a future/other programme) opens the panel, which surfaces
/// the synopsis plus the cell's one action; a "No information" filler offers no
/// action, so `infoTarget` is nil and `activate` tunes it straight through.
extension GuideGridModel {
    func infoTarget(for cell: GuideCell, row: GuideRow) -> GuideInfoTarget? {
        let selection = selectCell(cell, row: row)
        guard cell.hasInfo, !GuideCellActions.actions(for: selection).isEmpty else { return nil }
        return GuideInfoTarget(channel: row.channel, cell: cell, selection: selection)
    }
}

#if DEBUG
extension GuideGridModel {
    /// The first cell whose panel offers My List (a future/other info cell) — the
    /// cell the guide-menu screenshot proof opens, so the flippable row is shown.
    func firstInfoTarget() -> GuideInfoTarget? {
        for row in rows {
            for cell in row.cells {
                if let hit = infoTarget(for: cell, row: row), case .info = hit.selection {
                    return hit
                }
            }
        }
        return nil
    }

    /// Idempotently saves the cell behind `target` (the DEBUG "Remove" variant).
    func ensureSaved(_ target: GuideInfoTarget) {
        if !isSaved(channel: target.channel, cell: target.cell) {
            toggleMyList(channel: target.channel, cell: target.cell)
        }
    }
}
#endif
