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
        setOverlay(.zapInfo)
    }

    /// Pin the info overlay open (no spinner) — `-tellyOverlay info`.
    func debugPresentInfoOverlay() {
        debugHoldFrame = true
        setOverlay(.info)
    }

    /// Pin the expanded transport overlay open — `-tellyOverlay transport`.
    func debugPresentTransportOverlay() {
        debugHoldFrame = true
        setOverlay(.infoTransport)
    }

    /// Pin the quick-bar open — `-tellyOverlay quickBar`.
    func debugPresentQuickBarOverlay() {
        debugHoldFrame = true
        setOverlay(.quickBar)
    }

    /// Pin the channel panel open — `-tellyOverlay panel`.
    func debugPresentPanelOverlay() {
        debugHoldFrame = true
        setOverlay(.panel)
    }

    /// Pin a track picker open over the quick-bar with the canned fixture snapshot
    /// (`-tellyOverlay trackAudio|trackSubtitles`).
    func debugPresentTrackPicker(_ kind: TrackPickerKind) {
        debugHoldFrame = true
        debugSnapshot = DebugLaunch.trackFixtureSnapshot()
        setOverlay(.pushed(.trackPicker(kind), back: .quickBar))
    }

    /// Pin the multiview pane menu open over a 2-pane engine-free grid so the
    /// full row set (incl. Remove + Add) renders — `-tellyOverlay multiviewMenu`.
    func debugPresentMultiviewPaneMenu() {
        debugSeedMultiviewSession(paneCount: 2)
        multiview?.openMenu()
    }

    /// Pin the Add-pane channel picker open over a 2-pane engine-free grid —
    /// `-tellyOverlay multiviewPicker`.
    func debugPresentMultiviewPicker() {
        debugSeedMultiviewSession(paneCount: 2)
        multiview?.openPicker(.add)
    }

    /// Raise an engine-free multiview session of `paneCount` fake tiles (held
    /// frame, nothing decoded) as the base for the pane-menu / picker proofs.
    private func debugSeedMultiviewSession(paneCount: Int) {
        debugHoldFrame = true
        let seed = Array(channels.prefix(paneCount))
        guard let grid = MultiviewGrid(channels: seed, capacity: 4,
                                       activeChannelId: seed.first?.id) else { return }
        enterMultiview(MultiviewSession(grid: grid))
    }

    /// Deliver a real remote `key` through ``onKey(_:)`` so the resolved command
    /// honours the model's captured ``keymap``, then pin the resulting overlay
    /// (frame held) — the keymap-remap proof (`-tellyKeymapUpDown switch`).
    func debugApplyKey(_ key: PlaybackKey) {
        debugHoldFrame = true
        onKey(key)
        setOverlay(overlay)
    }
}
#endif
