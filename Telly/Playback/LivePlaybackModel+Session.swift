import Foundation

/// The live stage's top-level mode, as one value so the two sub-machines can never
/// disagree: EITHER single-stream playback with its overlay machine
/// (``OverlayVisibility`` — none / info / zap / quick-bar / panel / pushed card),
/// OR the N-up ``MultiviewSession`` with its own grid / menu / picker layer. The
/// `.multiview` ``PlaybackOverlay`` the key policy sees is DERIVED from this, and
/// a session can only exist inside `.multiview`.
enum LiveSession {
    case single(OverlayVisibility)
    case multiview(MultiviewSession)
}

/// The session accessors + the only mutators of ``LivePlaybackModel/session``.
extension LivePlaybackModel {
    /// The overlay layer the screen should render this frame.
    var overlay: PlaybackOverlay {
        switch session {
        case let .single(visibility): return visibility.overlay
        case .multiview: return .multiview
        }
    }

    /// The live multiview session while in multiview, else nil.
    var multiview: MultiviewSession? {
        if case let .multiview(session) = session { return session }
        return nil
    }

    /// Mutate the single-stream overlay machine; a no-op inside multiview.
    func updateOverlay(_ change: (inout OverlayVisibility) -> Void) {
        guard case var .single(visibility) = session else { return }
        change(&visibility)
        session = .single(visibility)
    }

    /// Sticky overlay (panel, menus, pushed cards); cancels any auto-hide.
    func setOverlay(_ next: PlaybackOverlay) { updateOverlay { $0.set(next) } }

    /// Transient overlay with its auto-hide armed from `now()`.
    func showAutoHiding(_ next: PlaybackOverlay, timeoutMs: Int) {
        updateOverlay { $0.showAutoHiding(next, timeoutMs: timeoutMs, at: now()) }
    }

    /// D-pad browsing keeps a transient overlay alive (restarts its countdown).
    func keepOverlayAlive() { updateOverlay { $0.keepAlive(at: now()) } }

    /// Apply elapsed time to the transient overlay (the tick).
    func resolveOverlay() { updateOverlay { $0.resolve(at: now()) } }

    /// Enter multiview with `session` (the overlay becomes `.multiview` by construction).
    func enterMultiview(_ multiview: MultiviewSession) { session = .multiview(multiview) }

    /// Leave multiview back to bare single-stream playback.
    func leaveMultiview() { session = .single(OverlayVisibility()) }
}
