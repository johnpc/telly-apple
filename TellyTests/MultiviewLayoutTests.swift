import Testing
@testable import Telly

/// The pure multiview grid geometry: column cap, ceiling rows, and the empty
/// collapse. Exhaustive over the supported 1-4 tile counts at cap 2.
struct MultiviewLayoutTests {
    @Test func oneTileIsSingleCell() {
        #expect(MultiviewLayout.dimensions(count: 1, maxColumns: 2) == (rows: 1, columns: 1))
    }

    @Test func twoTilesIsOneRowTwoColumns() {
        #expect(MultiviewLayout.dimensions(count: 2, maxColumns: 2) == (rows: 1, columns: 2))
    }

    @Test func threeTilesIsTwoByTwo() {
        #expect(MultiviewLayout.dimensions(count: 3, maxColumns: 2) == (rows: 2, columns: 2))
    }

    @Test func fourTilesIsTwoByTwo() {
        #expect(MultiviewLayout.dimensions(count: 4, maxColumns: 2) == (rows: 2, columns: 2))
    }

    @Test func columnsNeverExceedCount() {
        #expect(MultiviewLayout.dimensions(count: 1, maxColumns: 3) == (rows: 1, columns: 1))
    }

    @Test func higherCapWidensRow() {
        #expect(MultiviewLayout.dimensions(count: 3, maxColumns: 3) == (rows: 1, columns: 3))
    }

    @Test func zeroCountCollapsesToEmpty() {
        #expect(MultiviewLayout.dimensions(count: 0, maxColumns: 2) == (rows: 0, columns: 0))
    }

    @Test func zeroColumnsCollapsesToEmpty() {
        #expect(MultiviewLayout.dimensions(count: 4, maxColumns: 0) == (rows: 0, columns: 0))
    }
}
