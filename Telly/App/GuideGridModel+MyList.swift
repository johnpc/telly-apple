import Foundation

/// The guide cell's My List add/remove logic — the Apple mirror of the My List
/// row in Android's `GuideScreenCellMenu` (capture 27), reusing the SAME shared
/// ``MyListToggling`` over the injected ``MyListStore`` as the Search entry point
/// (no parallel toggle path). A nil store makes every call a no-op.
extension GuideGridModel {
    /// The programme action menu to present for `cell`, or nil when activation is
    /// not an info-cell menu (airing / catch-up / filler cells never open it).
    func cellMenuTarget(for cell: GuideCell, row: GuideRow) -> GuideCellMenuTarget? {
        guard case .info = selectCell(cell, row: row),
              GuideCellActions.actions(for: cell).contains(.myList) else { return nil }
        return GuideCellMenuTarget(channel: row.channel, cell: cell)
    }

    /// Whether the cell's programme is already saved (drives the menu label).
    func isSaved(channel: ChannelEntity, cell: GuideCell) -> Bool {
        guard let program = cell.program else { return false }
        return MyListToggle.isSaved(keys: myListKeys, channelKey: ChannelImporter.keyOf(channel),
                                    startMs: program.startMs)
    }

    /// Saves the cell's programme, or removes it when already saved, then reloads keys.
    func toggleMyList(channel: ChannelEntity, cell: GuideCell) {
        guard let store = myListStore, let program = cell.program else { return }
        MyListToggling.apply(store: store, saved: isSaved(channel: channel, cell: cell),
            channelKey: ChannelImporter.keyOf(channel), title: program.details.title,
            description: program.details.description, startMs: program.startMs,
            endMs: program.endMs, addedAtMs: now())
        refreshMyListKeys()
    }

    /// Reloads `myListKeys` from the store (the live saved-state the label reads).
    func refreshMyListKeys() { myListKeys = MyListToggling.keys(from: myListStore) }
}

#if DEBUG
extension GuideGridModel {
    /// The first non-airing info-cell's menu target across the loaded rows — the
    /// cell a real OK/tap would open; backs the DEBUG guide-menu screenshot proof.
    func firstCellMenuTarget() -> GuideCellMenuTarget? {
        for row in rows {
            for cell in row.cells {
                if let hit = cellMenuTarget(for: cell, row: row) { return hit }
            }
        }
        return nil
    }

    /// Idempotently saves the cell behind `target` (the DEBUG "Remove" variant).
    func ensureSaved(_ target: GuideCellMenuTarget) {
        if !isSaved(channel: target.channel, cell: target.cell) {
            toggleMyList(channel: target.channel, cell: target.cell)
        }
    }
}
#endif
