import Foundation

/// Runtime pane mutation for ``MultiviewSession``: add / remove / swap a tile
/// while keeping `engines` index-aligned to `grid.cells`. Every path drives the
/// pure ``MultiviewGrid`` transforms first, then mirrors the change onto the
/// engine set — minting + loading a fresh engine on add, and stopping + releasing
/// (the same teardown discipline as ``close()``) on remove — before re-applying
/// the one-audible-tile mute policy. Split out so the session core stays capped.
extension MultiviewSession {
    /// Append `channel` as a new pane, minting + loading its engine (muted until
    /// activated). A no-op when the grid rejects it (at capacity or a duplicate).
    func addPane(_ channel: ChannelEntity) {
        let next = grid.added(channel)
        guard next != grid else { return }
        if let make = makeTileEngine {
            let engine = make()
            engine.load(channel.source.streamUrl, isLive: true)
            engines.append(engine)
        }
        retarget(next)
    }

    /// Remove the pane at `index`, tearing down its engine, then re-lay-out the
    /// rest. A no-op for the last remaining pane or an out-of-range index.
    func removePane(at index: Int) {
        let next = grid.removed(at: index)
        guard next != grid else { return }
        if engines.indices.contains(index) {
            engines[index].stop()
            engines[index].release()
            engines.remove(at: index)
        }
        retarget(next)
    }

    /// Swap the pane at `index` to `channel`, reloading just that pane's engine.
    func changeChannel(at index: Int, to channel: ChannelEntity) {
        let next = grid.replaced(at: index, with: channel)
        guard next != grid else { return }
        engine(at: index)?.load(channel.source.streamUrl, isLive: true)
        retarget(next)
    }
}
