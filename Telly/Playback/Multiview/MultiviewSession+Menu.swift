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

    /// The open pane menu, or nil when the layer is the grid or the picker.
    var menu: MultiviewPaneMenu? {
        if case let .menu(menu) = layer { return menu }
        return nil
    }

    /// The open channel picker, or nil when the layer is the grid or the menu.
    var picker: MultiviewPicker? {
        if case let .picker(picker) = layer { return picker }
        return nil
    }

    /// Open the pane menu over the active tile (replacing any picker).
    func openMenu() { layer = .menu(MultiviewPaneMenu()) }

    /// Close the pane menu, returning to the bare grid.
    func closeMenu() { layer = .grid }

    /// Step the pane-menu highlight, clamped into the visible row range.
    func moveMenu(_ delta: Int) {
        guard let current = menu else { return }
        layer = .menu(MultiviewPaneMenu(selection:
            MultiviewMenuPolicy.moved(selection: current.selection, by: delta,
                                      count: menuRows.count)))
    }

    /// The highlighted pane-menu row, or nil when the menu is closed.
    var selectedMenuRow: MultiviewMenuRow? {
        guard let menu, menuRows.indices.contains(menu.selection) else { return nil }
        return menuRows[menu.selection]
    }

    /// Open the channel picker in `mode` (replacing the menu).
    func openPicker(_ mode: MultiviewPickerMode) { layer = .picker(MultiviewPicker(mode: mode)) }

    /// Close the picker, returning to the bare grid.
    func closePicker() { layer = .grid }

    /// Step the picker highlight, clamped into `0..<count`.
    func movePicker(_ delta: Int, count: Int) {
        guard let current = picker else { return }
        layer = .picker(MultiviewPicker(mode: current.mode,
            selection: MultiviewMenuPolicy.moved(selection: current.selection,
                                                 by: delta, count: count)))
    }
}
