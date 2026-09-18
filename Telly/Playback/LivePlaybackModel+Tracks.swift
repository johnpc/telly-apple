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

    /// Open the picker for `kind`: remember it and push over the quick-bar so
    /// BACK pops straight back there via the pure ``PlaybackKeyPolicy``.
    func openTrackPicker(_ kind: TrackPickerKind) {
        activePicker = kind
        visibility.set(.pushed(back: .quickBar))
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
        case .audio: openTrackPicker(.audio)
        case .subtitles: openTrackPicker(.subtitles)
        case .latency: openTrackPicker(.sync)
        #if os(iOS)
        case .pictureInPicture: requestPip()
        #endif
        default: break
        }
    }

    /// The captions quick-bar slot label from the live snapshot ("Off" until set).
    var quickBarSubtitles: String { TrackLabels.subtitleSlot(trackSnapshot) }

    /// The audio-sync quick-bar slot label from the live offset ("0 ms", "+50 ms").
    var quickBarSync: String { TrackLabels.sync(engine.tracks.audioOffsetMs) }
}

#if os(iOS)
extension LivePlaybackModel {
    /// Whether the PiP quick-bar slot should accept a tap right now: the device
    /// supports PiP and live video is actually playing (a later slice hands the
    /// frames to the system PiP window).
    var pipActionable: Bool {
        PipEligibility.isActionable(isSupported: isPipSupported, state: engine.state)
    }

    /// Entry point for the `.pictureInPicture` quick-bar slot: record the PiP
    /// intent when actionable. The later AVKit slice consumes ``pipRequested``.
    func requestPip() {
        guard pipActionable else { return }
        pipRequested = true
    }
}
#endif
