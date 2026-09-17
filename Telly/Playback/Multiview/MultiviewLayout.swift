import Foundation

/// Pure multiview grid geometry: how many rows and columns hold `count` tiles,
/// capped at `maxColumns`. At `maxColumns` 2 this yields 1→1x1, 2→1x2, 3-4→2x2.
/// Columns are the lesser of the tile count and the cap; rows are the ceiling of
/// the count over the column width. No engines, no view — layout math only.
enum MultiviewLayout {
    /// The (rows, columns) that fit `count` tiles within `maxColumns` columns.
    /// A non-positive `count` or `maxColumns` collapses to an empty (0, 0) grid.
    static func dimensions(count: Int, maxColumns: Int) -> (rows: Int, columns: Int) {
        guard count > 0, maxColumns > 0 else { return (rows: 0, columns: 0) }
        let columns = min(count, maxColumns)
        let rows = (count + columns - 1) / columns
        return (rows: rows, columns: columns)
    }
}
