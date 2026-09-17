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

    /// Enter multiview: build the grid, spin up one engine per tile, load every
    /// stream (only the active tile audible), and raise the sticky overlay.
    func openMultiview() {
        guard let grid = multiviewGrid() else { return }
        let session = MultiviewSession(grid: grid, makeEngine: makeEngine)
        session.start()
        multiview = session
        visibility.set(.multiview)
    }

    /// Move the active tile one D-pad step, re-applying the mute policy.
    func moveMultiviewActive(_ direction: MultiviewDirection) {
        multiview?.moveActive(direction)
    }

    /// Promote the active tile to fullscreen: tear multiview down, then tune it.
    func promoteMultiviewActive() {
        guard let channel = multiview?.grid.activeCell?.channel else { return }
        exitMultiview()
        tune(channel)
    }

    /// Leave multiview: release every tile engine and return to single playback.
    func exitMultiview() {
        multiview?.close()
        multiview = nil
        visibility.set(.none)
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
