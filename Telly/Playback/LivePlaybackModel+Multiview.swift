import Foundation

extension LivePlaybackModel {
    /// The multiview tile cap. tvOS may drop to 2 pending on-device decode
    /// verification (4 concurrent MPEG-TS can saturate the Apple TV); the value
    /// is centralised here so that fallback is a one-line change.
    private var multiviewCapacity: Int { 4 }

    /// The starting grid: a SINGLE pane on the tuned channel (Android's model —
    /// enter with one, add more up to `multiviewCapacity` from the pane menu),
    /// falling back to the first channel when nothing is tuned yet.
    private func multiviewGrid() -> MultiviewGrid? {
        let seed = current.map { [$0] } ?? Array(channels.prefix(1))
        return MultiviewGrid(channels: seed, capacity: multiviewCapacity,
                             activeChannelId: current?.id)
    }

    /// The full channel list the pane-menu picker chooses from.
    var multiviewPickerChannels: [ChannelEntity] { channels }

    /// Enter multiview: build the grid, stop the primary fullscreen engine (so its
    /// audio can't compete with the active tile), spin up one engine per tile,
    /// load every stream (only the active tile audible), and raise the sticky
    /// overlay.
    func openMultiview() {
        guard let grid = multiviewGrid() else { return }
        engine.stop()
        let session = MultiviewSession(grid: grid, makeEngine: makeEngine)
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
