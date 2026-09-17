import SwiftUI

/// Lays the multiview tiles into the computed rows×columns grid. `maxColumns`
/// forks by platform — tvOS and iPad both use 2 (the 2x2 cap) — and that fork is
/// confined to this leaf view. iPhone still renders (a 2-up is legible) but is
/// not a screenshot target. Empty trailing slots (a 3-tile 2x2) stay clear.
struct MultiviewGridView: View {
    let session: MultiviewSession

    var body: some View {
        let cells = session.grid.cells
        let dims = MultiviewLayout.dimensions(count: cells.count, maxColumns: maxColumns)
        VStack(spacing: 8) {
            ForEach(0..<dims.rows, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(0..<dims.columns, id: \.self) { column in
                        cellAt(row * dims.columns + column)
                    }
                }
            }
        }
        .padding(8)
    }

    @ViewBuilder private func cellAt(_ index: Int) -> some View {
        let cells = session.grid.cells
        if cells.indices.contains(index) {
            MultiviewCellView(cell: cells[index], engine: session.engine(at: index),
                              isActive: index == session.grid.activeIndex,
                              onActivate: { session.setActive(index) })
        } else {
            Color.clear
        }
    }

    private var maxColumns: Int {
        #if os(tvOS)
        return 2
        #else
        return 2
        #endif
    }
}
