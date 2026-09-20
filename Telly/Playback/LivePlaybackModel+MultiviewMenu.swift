import Foundation

/// The pane-menu + channel-picker orchestration over ``MultiviewSession``. OK on a
/// tile opens the pane menu (Android's OK-on-pane semantics); its rows change the
/// pane's channel, promote it to fullscreen, remove it, or add another. Sub-mode
/// keys route through the pure ``MultiviewMenuPolicy`` here — BEFORE the grid-level
/// ``PlaybackKeyPolicy`` — so the same D-pad drives both 1-D lists; every channel
/// load/teardown runs over the session's engine seam.
extension LivePlaybackModel {
    /// Open the pane menu over the active tile (grid-level OK).
    func openMultiviewPaneMenu() { multiview?.openMenu() }

    /// Route a key while a pane menu or picker is up; nil when neither is (so the
    /// caller falls through to the grid-level policy).
    func handleMultiviewSubKey(_ key: PlaybackKey) -> Bool? {
        guard let session = multiview else { return nil }
        if session.picker != nil { return handlePickerKey(session, key) }
        if session.menu != nil { return handleMenuKey(session, key) }
        return nil
    }

    private func handleMenuKey(_ session: MultiviewSession, _ key: PlaybackKey) -> Bool {
        switch MultiviewMenuPolicy.action(for: key) {
        case let .move(delta): session.moveMenu(delta)
        case .activate: activateMultiviewMenuRow()
        case .close: session.closeMenu()
        case .ignored: return false
        }
        return true
    }

    private func handlePickerKey(_ session: MultiviewSession, _ key: PlaybackKey) -> Bool {
        switch MultiviewMenuPolicy.action(for: key) {
        case let .move(step): session.movePicker(step, count: multiviewPickerChannels.count)
        case .activate: pickHighlightedMultiviewChannel()
        case .close: session.closePicker()
        case .ignored: return false
        }
        return true
    }

    /// Run the highlighted pane-menu row (OK in the menu, or a tap on tvOS/iPad).
    func activateMultiviewMenuRow() {
        guard let row = multiview?.selectedMenuRow else { return }
        runMultiviewMenuRow(row)
    }

    /// Dispatch a specific pane-menu row — the shared body for key + tap entry.
    func runMultiviewMenuRow(_ row: MultiviewMenuRow) {
        switch row {
        case .changeChannel: multiview?.openPicker(.change)
        case .fullscreen: promoteMultiviewActive()
        case .removePane: removeActiveMultiviewPane()
        case .addPane: multiview?.openPicker(.add)
        }
    }

    private func removeActiveMultiviewPane() {
        guard let session = multiview else { return }
        session.removePane(at: session.grid.activeIndex)
        session.closeMenu()
    }

    private func pickHighlightedMultiviewChannel() {
        guard let picker = multiview?.picker,
              multiviewPickerChannels.indices.contains(picker.selection) else { return }
        selectMultiviewChannel(multiviewPickerChannels[picker.selection])
    }

    /// Apply a picked channel: swap the active pane (`.change`) or add a new pane
    /// (`.add`), then close the picker back to the grid. The tap entry for rows.
    func selectMultiviewChannel(_ channel: ChannelEntity) {
        guard let session = multiview, let picker = session.picker else { return }
        switch picker.mode {
        case .change: session.changeChannel(at: session.grid.activeIndex, to: channel)
        case .add: session.addPane(channel)
        }
        session.closePicker()
    }
}
