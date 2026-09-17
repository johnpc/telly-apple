import Foundation

/// The live multiview engine set: one ``PlayerEngine`` per tile, index-aligned to
/// the grid's cells, with exactly the active tile audible. Every decision (which
/// URL loads where, who is muted, where focus lands) runs over the engine seam so
/// a fake stands in for tests; real decode is the view's `VideoSurfaceView` layer.
/// Mirrors ``LivePlaybackModel``'s single-engine ownership, scaled to N tiles.
@MainActor
@Observable
final class MultiviewSession {
    private(set) var grid: MultiviewGrid
    let engines: [any PlayerEngine]
    let maxColumns: Int

    init(grid: MultiviewGrid, maxColumns: Int = 2,
         makeEngine: () -> any PlayerEngine) {
        self.grid = grid
        self.maxColumns = maxColumns
        self.engines = grid.cells.map { _ in makeEngine() }
    }

    #if DEBUG
    /// An engine-free session for the screenshot proof: every tile renders its
    /// fake colour+name surface (no `VideoSurfaceView` layered, nothing decoded).
    init(grid: MultiviewGrid, maxColumns: Int = 2) {
        self.grid = grid
        self.maxColumns = maxColumns
        self.engines = []
    }
    #endif

    /// The engine backing tile `index`, or nil when out of range (fake tiles).
    func engine(at index: Int) -> (any PlayerEngine)? {
        engines.indices.contains(index) ? engines[index] : nil
    }

    /// Tunes each tile's stream (index-aligned) and applies the mute policy.
    func start() {
        for (index, engine) in engines.enumerated() where grid.cells.indices.contains(index) {
            engine.load(grid.cells[index].streamUrl)
        }
        applyAudio()
    }

    /// Makes tile `index` the active (audible, ringed) one.
    func setActive(_ index: Int) {
        grid = grid.withActive(index)
        applyAudio()
    }

    /// Moves the active tile one D-pad step and re-applies the mute policy.
    func moveActive(_ direction: MultiviewDirection) {
        let dims = MultiviewLayout.dimensions(count: grid.cells.count, maxColumns: maxColumns)
        setActive(MultiviewFocus.moved(active: grid.activeIndex, direction: direction,
                                       rows: dims.rows, columns: dims.columns,
                                       count: grid.cells.count))
    }

    /// Stops and releases every engine (teardown on exit).
    func close() {
        for engine in engines {
            engine.stop()
            engine.release()
        }
    }

    /// Exactly the active tile is audible; every other tile is muted.
    private func applyAudio() {
        for (index, engine) in engines.enumerated() {
            engine.setMuted(index != grid.activeIndex)
        }
    }
}
