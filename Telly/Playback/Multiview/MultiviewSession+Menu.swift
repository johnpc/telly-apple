import Foundation

/// The pane-menu / channel-picker interaction state on ``MultiviewSession``: the
/// bare grid, a pane menu highlighting one row, or a channel picker highlighting
/// one channel. All highlight motion clamps through ``MultiviewMenuPolicy`` so the
/// two 1-D lists behave identically. Pure state transitions — the model maps them
/// onto the engine mutations; the view just renders whichever layer is open.
extension MultiviewSession {
    /// The pane-menu rows for the current pane count vs the grid's capacity.
    var menuRows: [MultiviewMenuRow] {
        MultiviewMenu.rows(paneCount: grid.cells.count, capacity: grid.capacity)
    }

    /// Open the pane menu over the active tile (closing any picker).
    func openMenu() {
        picker = nil
        menu = MultiviewPaneMenu()
    }

    /// Close the pane menu, returning to the bare grid.
    func closeMenu() { menu = nil }

    /// Step the pane-menu highlight, clamped into the visible row range.
    func moveMenu(_ delta: Int) {
        guard let current = menu else { return }
        menu = MultiviewPaneMenu(selection:
            MultiviewMenuPolicy.moved(selection: current.selection, by: delta,
                                      count: menuRows.count))
    }

    /// The highlighted pane-menu row, or nil when the menu is closed.
    var selectedMenuRow: MultiviewMenuRow? {
        guard let menu, menuRows.indices.contains(menu.selection) else { return nil }
        return menuRows[menu.selection]
    }

    /// Open the channel picker in `mode` (replacing the menu).
    func openPicker(_ mode: MultiviewPickerMode) {
        menu = nil
        picker = MultiviewPicker(mode: mode)
    }

    /// Close the picker, returning to the bare grid.
    func closePicker() { picker = nil }

    /// Step the picker highlight, clamped into `0..<count`.
    func movePicker(_ delta: Int, count: Int) {
        guard let current = picker else { return }
        picker = MultiviewPicker(mode: current.mode,
            selection: MultiviewMenuPolicy.moved(selection: current.selection,
                                                 by: delta, count: count))
    }
}
