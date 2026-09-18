import SwiftUI

extension View {
    /// Overlay show / hide motion shared by every fullscreen-playback layer
    /// (info, zap, quick-bar, panel, track picker, multiview): a graceful fade +
    /// subtle ~10pt rise on appear (`Motion.overlayIn`) and a quick fade on
    /// dismiss (`Motion.overlayOut`) — asymmetric, matching the Android reference.
    /// Instant under Reduce Motion. Pair with `.animation(_, value: overlay)` on
    /// the host ZStack so the state change opens an animation transaction.
    func overlayTransition(reduceMotion: Bool) -> some View {
        transition(.asymmetric(
            insertion: .opacity.combined(with: .offset(y: Motion.overlayRise))
                .animation(Motion.gated(Motion.overlayIn, reduceMotion: reduceMotion)),
            removal: .opacity
                .animation(Motion.gated(Motion.overlayOut, reduceMotion: reduceMotion))))
    }

    /// Top-level route / screen swap: a fast linear crossfade, no slide — one
    /// surface dissolves into the next. Timing comes from the host's ambient
    /// `.animation(Motion.route, value:)`, so Reduce Motion (a nil ambient
    /// animation) makes the swap instant.
    func routeTransition() -> some View {
        transition(.opacity)
    }
}
