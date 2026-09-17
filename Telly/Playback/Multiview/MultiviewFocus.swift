import Foundation

/// A D-pad move within the multiview grid.
enum MultiviewDirection: Equatable, Sendable { case up, down, left, right }

/// Pure 2D focus navigation over the multiview grid: steps the active tile one
/// cell in `direction` with floor-mod wraparound at every edge, skipping index
/// positions that hold no tile (a partial grid), and returning the current
/// `active` when no valid tile can be reached. No engines, no view — index math
/// split into small helpers so each stays well inside the difficulty budget.
enum MultiviewFocus {
    /// The index the active tile moves to for `direction`, wrapping around edges
    /// and hopping over empty trailing slots; `active` again when nowhere lands.
    static func moved(active: Int, direction: MultiviewDirection,
                      rows: Int, columns: Int, count: Int) -> Int {
        guard min(count, rows, columns) > 0 else { return active }
        var at = origin(of: active, columns: columns)
        for _ in 0..<span(direction, rows: rows, columns: columns) {
            at = stepped(at, direction, rows: rows, columns: columns)
            let candidate = flatten(at, columns: columns)
            if lands(candidate, count: count, from: active) { return candidate }
        }
        return active
    }

    /// Whether `candidate` is a real tile other than where we started.
    private static func lands(_ candidate: Int, count: Int, from active: Int) -> Bool {
        candidate < count && candidate != active
    }

    /// The (row, column) an index sits at within a `columns`-wide grid.
    private static func origin(of index: Int, columns: Int) -> (row: Int, column: Int) {
        (row: index / columns, column: index % columns)
    }

    /// The flat index of a (row, column) within a `columns`-wide grid.
    private static func flatten(_ at: (row: Int, column: Int), columns: Int) -> Int {
        at.row * columns + at.column
    }

    /// How many wrapped steps a full traversal takes along `direction`'s axis.
    private static func span(_ direction: MultiviewDirection, rows: Int, columns: Int) -> Int {
        switch direction {
        case .up, .down: return rows
        case .left, .right: return columns
        }
    }

    /// One wrapped step of the (row, column) cursor in `direction`.
    private static func stepped(_ at: (row: Int, column: Int), _ direction: MultiviewDirection,
                                rows: Int, columns: Int) -> (row: Int, column: Int) {
        switch direction {
        case .up:    return (wrapped(at.row - 1, rows), at.column)
        case .down:  return (wrapped(at.row + 1, rows), at.column)
        case .left:  return (at.row, wrapped(at.column - 1, columns))
        case .right: return (at.row, wrapped(at.column + 1, columns))
        }
    }

    /// Floor-mod so a step off either edge lands on the opposite edge.
    private static func wrapped(_ value: Int, _ size: Int) -> Int {
        (value % size + size) % size
    }
}
