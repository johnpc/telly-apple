import Foundation

extension LivePlaybackModel {
    /// The multiview tile cap. tvOS may drop to 2 pending on-device decode
    /// verification (4 concurrent MPEG-TS can saturate the Apple TV); the value
    /// is centralised here so that fallback is a one-line change.
    private var multiviewCapacity: Int { 4 }

    /// The grid over the current visible channels, active on the tuned one.
    private func multiviewGrid() -> MultiviewGrid? {
        MultiviewGrid(channels: channels, capacity: multiviewCapacity,
                      activeChannelId: current?.id)
    }

    /// Enter multiview: build the grid, stop the primary fullscreen engine (so its
    /// audio can't compete with the active tile), spin up one engine per tile,
    /// load every unblocked stream (only the active tile audible), and raise the
    /// sticky overlay. The active tile is PIN-gated exactly like a fullscreen tune.
    func openMultiview() {
        guard let grid = multiviewGrid() else { return }
        if let active = grid.activeCell?.channel, blockGate?.intercept(active) == true { return }
        engine.stop()
        let session = MultiviewSession(grid: grid, makeEngine: makeEngine,
                                       canLoad: { [blockGate] in blockGate?.blocks($0) != true })
        session.start()
        multiview = session
        visibility.set(.multiview)
    }

    /// Move the active tile one D-pad step, re-applying the mute policy.
    func moveMultiviewActive(_ direction: MultiviewDirection) {
        multiview?.moveActive(direction)
    }

    /// Promote the active tile to fullscreen: tear multiview down, then tune it
    /// (which re-loads the primary engine for that channel).
    func promoteMultiviewActive() {
        guard let channel = multiview?.grid.activeCell?.channel else { return }
        teardownMultiview()
        tune(channel)
    }

    /// Leave multiview: release every tile engine and restore single playback of
    /// the previously-active channel on the primary engine.
    func exitMultiview() {
        teardownMultiview()
        restorePrimaryPlayback()
    }

    /// Release the tile engines and drop the overlay without touching the primary.
    private func teardownMultiview() {
        multiview?.close()
        multiview = nil
        visibility.set(.none)
    }

    /// Reload the previously-active channel on the primary engine so single
    /// playback resumes where it left off before multiview opened.
    private func restorePrimaryPlayback() {
        guard let channel = current else { return }
        engine.load(channel.source.streamUrl, isLive: true)
    }
}

#if DEBUG
extension LivePlaybackModel {
    /// DEBUG screenshot hook: raise the multiview overlay with an engine-free
    /// session (colour+name tiles, nothing decoded) for the `-tellyOverlay
    /// multiview` proof; the held frame keeps a spinner off the stage.
    func debugPresentMultiviewOverlay() {
        debugHoldFrame = true
        guard let grid = multiviewGrid() else { return }
        multiview = MultiviewSession(grid: grid)
        visibility.set(.multiview)
    }
}
#endif
