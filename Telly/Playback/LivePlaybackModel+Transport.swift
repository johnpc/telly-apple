import Foundation

/// The live transport actions of ``LivePlaybackModel`` — play/pause and the
/// iPhone-tap entry point for the expanded `.infoTransport` row — split into a
/// sibling extension so the base type stays within the source-line budget. Both
/// route through the engine seam and the shared ``execute(_:)`` command runner,
/// never around them, so tvOS remote presses and iOS taps drive identical logic.
extension LivePlaybackModel {
    /// Freeze or resume the live stream. A live pause falls behind the live edge
    /// (there is no seek-forward — the `isLive` seam keeps the stream unscrubbable),
    /// so this only toggles the engine's paused flag.
    func togglePlayPause() {
        if engine.paused { engine.resume() } else { engine.pause() }
    }

    /// iPhone/iPad tap on a transport control: keep the overlay alive, focus the
    /// tapped control, then run its command — the touch mirror of the remote's
    /// LEFT/RIGHT-then-OK, funnelled through the same ``execute(_:)`` path.
    func tapTransport(_ button: LiveTransportButton) {
        visibility.keepAlive(at: now())
        transportFocus = button
        execute(button.command)
    }
}
