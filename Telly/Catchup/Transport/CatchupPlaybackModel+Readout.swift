import Foundation

/// The transport row's readout values for ``CatchupPlaybackModel`` (position /
/// duration / paused), split out so the model stays within the source-line
/// budget. The DEBUG screenshot overrides are honoured here so the proof can hold
/// a scrubbed position without a decoded stream.
extension CatchupPlaybackModel {
    /// The transport-row position, ms from the archive start.
    var positionMs: Int {
        #if DEBUG
        if let debugPosition { return debugPosition }
        #endif
        return tracker.position
    }

    /// The finite archive length (from the EPG window), 0 when idle.
    var durationMs: Int { state?.request.durationMs ?? 0 }

    /// Whether the transport row should show the paused pill.
    var isPaused: Bool {
        #if DEBUG
        if let debugPaused { return debugPaused }
        #endif
        return engine.paused
    }
}
