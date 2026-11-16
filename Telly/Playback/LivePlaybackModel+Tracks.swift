import Foundation

extension LivePlaybackModel {
    /// The snapshot feeding the picker: the DEBUG canned fixture when present
    /// (screenshot proof), otherwise the live engine's decoded tracks.
    private var trackSnapshot: TrackSnapshot {
        #if DEBUG
        if let debugSnapshot { return debugSnapshot }
        #endif
        return engine.tracks.snapshot
    }

    /// The track picker card currently pushed over the quick-bar, derived from
    /// the overlay state (nil when no track picker is up).
    var activePicker: TrackPickerKind? {
        if case let .pushed(.trackPicker(kind), _) = visibility.overlay { return kind }
        return nil
    }

    /// Open the picker for `kind`: push it over the quick-bar so BACK pops
    /// straight back there via the pure ``PlaybackKeyPolicy``.
    func openTrackPicker(_ kind: TrackPickerKind) {
        visibility.set(.pushed(.trackPicker(kind), back: .quickBar))
    }

    /// The rows the active picker renders (empty when none is open).
    var pickerRows: [TrackPickerRow] {
        guard let activePicker else { return [] }
        return TrackPickerRows.of(activePicker, trackSnapshot)
    }

    /// The active picker's dialog title (empty when none is open).
    var pickerTitle: String { activePicker?.title ?? "" }

    /// Apply a picker row: audio/captions close back to the quick-bar; the
    /// audio-sync stepper returns false and keeps the dialog open.
    func selectPickerRow(_ id: String) {
        guard let activePicker else { return }
        if TrackPickerRows.apply(activePicker, rowId: id, tracks: engine.tracks) {
            execute(.popTo(.quickBar))
        }
    }

    /// Route a quick-bar slot tap to its picker; the resolution slot is
    /// display-only for live IPTV (single video ES), so it does nothing.
    func onQuickBarAction(_ action: QuickBarAction) {
        switch action {
        case .search: searchRequested = true
        case .multiview: openMultiview()
        case .audio: openTrackPicker(.audio)
        case .subtitles: openTrackPicker(.subtitles)
        case .latency: openTrackPicker(.sync)
        case .resolution: openResizePicker()
        default: break
        }
    }

    /// The captions quick-bar slot label from the live snapshot ("Off" until set).
    var quickBarSubtitles: String { TrackLabels.subtitleSlot(trackSnapshot) }

    /// The audio-sync quick-bar slot label from the live offset ("0 ms", "+50 ms").
    var quickBarSync: String { TrackLabels.sync(engine.tracks.audioOffsetMs) }
}
