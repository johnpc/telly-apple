import Foundation

/// The multiview tile set and which tile is active (audible, ringed). Built from
/// the first `capacity` channels; immutable `added`/`removed`/`withActive`
/// transforms keep every mutation clamped and unit-tested without a view, mirror-
/// ing ``PanelSelection``. The user channel picker is a later slice — add/remove
/// are built and tested now so the grid is ready for it.
struct MultiviewGrid: Equatable {
    private(set) var cells: [MultiviewCell]
    private(set) var activeIndex: Int
    let capacity: Int

    /// Takes the first `capacity` channels as tiles, active on the one matching
    /// `activeChannelId` (else the first). Nil when there are no channels/capacity.
    init?(channels: [ChannelEntity], capacity: Int, activeChannelId: Int?) {
        let chosen = Array(channels.prefix(max(capacity, 0)))
        guard !chosen.isEmpty else { return nil }
        self.capacity = capacity
        self.cells = chosen.map(MultiviewCell.init)
        self.activeIndex = chosen.firstIndex { $0.id == activeChannelId } ?? 0
    }

    /// The active tile, or nil if the grid is somehow empty.
    var activeCell: MultiviewCell? {
        cells.indices.contains(activeIndex) ? cells[activeIndex] : nil
    }

    /// Appends `channel` as a new tile. A no-op at capacity or on a duplicate id.
    func added(_ channel: ChannelEntity) -> MultiviewGrid {
        guard cells.count < capacity,
              !cells.contains(where: { $0.id == channel.id }) else { return self }
        return with { $0.cells.append(MultiviewCell(channel: channel)) }
    }

    /// Removes the tile at `index`, keeping at least one tile and re-clamping the
    /// active index. A no-op for an out-of-range index or a single-tile grid.
    func removed(at index: Int) -> MultiviewGrid {
        guard cells.indices.contains(index), cells.count > 1 else { return self }
        return with {
            $0.cells.remove(at: index)
            $0.activeIndex = min($0.activeIndex, $0.cells.count - 1)
        }
    }

    /// Moves the active tile to `index`, clamped into the current tile range.
    func withActive(_ index: Int) -> MultiviewGrid {
        with { $0.activeIndex = min(max(index, 0), max($0.cells.count - 1, 0)) }
    }

    private func with(_ mutate: (inout MultiviewGrid) -> Void) -> MultiviewGrid {
        var copy = self
        mutate(&copy)
        return copy
    }
}
