import Foundation

/// One row of a picker dialog; `checked` marks the active option.
struct TrackPickerRow: Equatable {
    let id: String
    let label: String
    var checked: Bool = false
}

/// The rows each picker shows and what selecting one does. Video = "Auto" +
/// every rendition; audio = the stream's audio tracks; CC = "Off" + text
/// tracks; sync = a stepper (±25/50 ms within ±1000 ms) that keeps the dialog
/// open while the others close on pick. Ported from the Android
/// `TrackPickerRows`.
enum TrackPickerRows {
    static let auto = "auto"
    static let off = "off"
    static let syncLimitMs = 1_000
    private static let reset = "sync:reset"
    private static let syncPrefix = "sync:"
    private static let syncStepsMs = [-50, -25, 25, 50]

    static func of(_ kind: TrackPickerKind, _ snapshot: TrackSnapshot) -> [TrackPickerRow] {
        switch kind {
        case .video: return videoRows(snapshot)
        case .audio: return audioRows(snapshot)
        case .sync: return syncRows()
        case .subtitles: return textRows(snapshot)
        }
    }

    /// Applies `rowId` to `tracks`; true = the picker closes.
    @discardableResult
    static func apply(_ kind: TrackPickerKind, rowId: String, tracks: TrackFacade) -> Bool {
        switch kind {
        case .video: tracks.selectVideo(rowId == auto ? nil : rowId)
        case .audio: tracks.selectAudio(rowId)
        case .subtitles: tracks.selectText(rowId == off ? nil : rowId)
        case .sync: tracks.setAudioOffsetMs(stepped(rowId, tracks.audioOffsetMs))
        }
        return kind != .sync
    }

    private static func stepped(_ rowId: String, _ current: Int) -> Int {
        if rowId == reset { return 0 }
        guard let delta = Int(rowId.dropFirst(syncPrefix.count)) else { return current }
        return min(max(current + delta, -syncLimitMs), syncLimitMs)
    }

    private static func videoRows(_ s: TrackSnapshot) -> [TrackPickerRow] {
        [TrackPickerRow(id: auto, label: "Auto", checked: s.videoOverrideId == nil)] +
            s.videos.map { TrackPickerRow(id: $0.id, label: TrackLabels.video($0), checked: $0.id == s.videoOverrideId) }
    }

    private static func audioRows(_ s: TrackSnapshot) -> [TrackPickerRow] {
        s.audios.enumerated().map { index, track in
            TrackPickerRow(id: track.id, label: TrackLabels.audio(track, index: index), checked: track.id == s.selectedAudioId)
        }
    }

    private static func textRows(_ s: TrackSnapshot) -> [TrackPickerRow] {
        [TrackPickerRow(id: off, label: "Off", checked: s.selectedTextId == nil)] +
            s.texts.enumerated().map { index, track in
                TrackPickerRow(id: track.id, label: TrackLabels.text(track, index: index), checked: track.id == s.selectedTextId)
            }
    }

    private static func syncRows() -> [TrackPickerRow] {
        syncStepsMs.map { TrackPickerRow(id: "\(syncPrefix)\($0)", label: TrackLabels.sync($0)) } +
            [TrackPickerRow(id: reset, label: "Reset")]
    }
}
