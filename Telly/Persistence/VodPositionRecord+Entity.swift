import Foundation

extension VodPositionRecord {
    /// Builds a persistence row from a domain position (`Int` => `Int64` at the
    /// row boundary).
    init(_ p: VodPosition) {
        self.init(itemKey: p.itemKey, positionMs: Int64(p.positionMs),
                  durationMs: Int64(p.durationMs), updatedAtMs: Int64(p.updatedAtMs))
    }

    /// The domain position this row represents (narrows `Int64` => `Int`).
    var entity: VodPosition {
        VodPosition(itemKey: itemKey, positionMs: Int(positionMs),
                    durationMs: Int(durationMs), updatedAtMs: Int(updatedAtMs))
    }
}

/// One stored resume position: the movie's `itemKey`, how far in, its total
/// duration, and when it was last written.
struct VodPosition: Equatable {
    let itemKey: String
    let positionMs: Int
    let durationMs: Int
    let updatedAtMs: Int
}
