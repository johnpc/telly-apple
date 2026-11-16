import Foundation

/// The aspect-ratio (resize-mode) picker slice of ``LivePlaybackModel``, mirroring
/// the track-picker slice: opening pushes a titled card over the quick-bar (BACK
/// pops straight back via the pure ``PlaybackKeyPolicy``), and selecting a row
/// applies the mode to the engine, persists it, then closes. The rows and the
/// id↔mode mapping are the pure ``ResizeModeChoices``; nothing here touches VLC.
extension LivePlaybackModel {
    /// Whether the aspect-ratio picker card is pushed, derived from the overlay.
    var resizePickerActive: Bool {
        if case .pushed(.resizePicker, _) = overlay { return true }
        return false
    }

    /// Open the aspect-ratio picker from the quick-bar's video slot.
    func openResizePicker() {
        setOverlay(.pushed(.resizePicker, back: .quickBar))
    }

    /// The rows the aspect-ratio picker renders (empty when it is not open).
    var resizePickerRows: [TrackPickerRow] {
        guard resizePickerActive else { return [] }
        return ResizeModeChoices.rows(selected: resizeMode)
    }

    /// Apply a picked aspect-ratio row: set + persist the mode, push it to the
    /// live engine, and close back to the quick-bar. Unknown ids are ignored.
    func selectResizeRow(_ id: String) {
        guard let mode = ResizeModeChoices.mode(forId: id) else { return }
        resizeMode = mode
        persistResizeMode(mode)
        engine.setResizeMode(mode)
        execute(.popTo(.quickBar))
    }
}
