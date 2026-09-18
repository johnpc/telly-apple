#if DEBUG
import Foundation

/// The DEBUG screenshot hooks for ``LivePlaybackModel``, split out of the `+Tune`
/// sibling so both stay within the source-line budget. Each pins one overlay open
/// (sticky, no auto-hide) with the last frame held so the tick loop can't hide it
/// or show a buffering spinner before the simulator capture — the fake TS never
/// decodes, so these prove the chrome over a held black stage, not real video.
extension LivePlaybackModel {
    /// Pin the compact zap overlay open — `-tellyOverlay zap`.
    func debugPresentZapOverlay() {
        debugHoldFrame = true
        visibility.set(.zapInfo)
    }

    /// Pin the info overlay open (no spinner) — `-tellyOverlay info`.
    func debugPresentInfoOverlay() {
        debugHoldFrame = true
        visibility.set(.info)
    }

    /// Pin the expanded transport overlay open — `-tellyOverlay transport`.
    func debugPresentTransportOverlay() {
        debugHoldFrame = true
        visibility.set(.infoTransport)
    }

    /// Pin the quick-bar open — `-tellyOverlay quickBar`.
    func debugPresentQuickBarOverlay() {
        debugHoldFrame = true
        visibility.set(.quickBar)
    }

    /// Pin the channel panel open — `-tellyOverlay panel`.
    func debugPresentPanelOverlay() {
        debugHoldFrame = true
        visibility.set(.panel)
    }

    /// Pin a track picker open over the quick-bar with the canned fixture snapshot
    /// (`-tellyOverlay trackAudio|trackSubtitles`).
    func debugPresentTrackPicker(_ kind: TrackPickerKind) {
        debugHoldFrame = true
        debugSnapshot = DebugLaunch.trackFixtureSnapshot()
        activePicker = kind
        visibility.set(.pushed(back: .quickBar))
    }

    /// Deliver a real remote `key` through ``onKey(_:)`` so the resolved command
    /// honours the model's captured ``keymap``, then pin the resulting overlay
    /// (frame held) — the keymap-remap proof (`-tellyKeymapUpDown switch`).
    func debugApplyKey(_ key: PlaybackKey) {
        debugHoldFrame = true
        onKey(key)
        visibility.set(visibility.overlay)
    }
}
#endif
