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
    /// Index-aligned to `grid.cells`; grown/shrunk in lock-step by the mutation
    /// extension, so `internal` (not `private(set)`) to let that sibling edit it.
    var engines: [any PlayerEngine]
    let maxColumns: Int
    /// Mints an engine for a pane added at runtime; nil in the engine-free DEBUG
    /// session, where add/remove mutate the grid only (nothing to decode).
    let makeTileEngine: (@MainActor () -> any PlayerEngine)?
    /// The pane menu opened by OK on a tile, nil when the grid is bare.
    var menu: MultiviewPaneMenu?
    /// The channel picker opened from the pane menu, nil when none is up.
    var picker: MultiviewPicker?

    init(grid: MultiviewGrid, maxColumns: Int = 2,
         makeEngine: @escaping @MainActor () -> any PlayerEngine) {
        self.grid = grid
        self.maxColumns = maxColumns
        self.makeTileEngine = makeEngine
        self.engines = grid.cells.map { _ in makeEngine() }
    }

    #if DEBUG
    /// An engine-free session for the screenshot proof: every tile renders its
    /// fake colour+name surface (no `VideoSurfaceView` layered, nothing decoded).
    init(grid: MultiviewGrid, maxColumns: Int = 2) {
        self.grid = grid
        self.maxColumns = maxColumns
        self.makeTileEngine = nil
        self.engines = []
    }
    #endif

    /// Re-point the grid (used by the add/remove/swap transforms) and re-apply the
    /// mute policy so exactly the active tile stays audible.
    func retarget(_ next: MultiviewGrid) {
        grid = next
        applyAudio()
    }

    /// The engine backing tile `index`, or nil when out of range (fake tiles).
    func engine(at index: Int) -> (any PlayerEngine)? {
        engines.indices.contains(index) ? engines[index] : nil
    }

    /// Tunes each tile's stream (index-aligned) and applies the mute policy.
    func start() {
        for (index, engine) in engines.enumerated() where grid.cells.indices.contains(index) {
            engine.load(grid.cells[index].streamUrl, isLive: true)
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

    /// Exactly the active tile is audible; every other tile is muted. Internal so
    /// the mutation extension can re-apply it after add/remove/swap.
    func applyAudio() {
        for (index, engine) in engines.enumerated() {
            engine.setMuted(index != grid.activeIndex)
        }
    }
}
