import Testing
@testable import Telly

/// The multiview tile-set transforms: capacity truncation, active resolution,
/// the empty→nil init, add/remove clamping (dup no-op, keeps ≥1) and withActive
/// clamping. Pure — exercised directly without a view or engine.
struct MultiviewGridTests {
    private func ch(_ id: Int) -> ChannelEntity {
        ChannelEntity(id: id, playlistId: 1, number: id, sortIndex: id,
                      source: ChannelSource(name: "Ch\(id)", groupTitle: "Live",
                                            streamUrl: "http://127.0.0.1/\(id).ts"))
    }
    private var channels: [ChannelEntity] { [ch(10), ch(20), ch(30), ch(40), ch(50)] }

    @Test func truncatesToCapacity() {
        let grid = MultiviewGrid(channels: channels, capacity: 4, activeChannelId: nil)
        #expect(grid?.cells.count == 4)
        #expect(grid?.cells.map(\.id) == [10, 20, 30, 40])
    }

    @Test func cellCarriesStreamUrl() {
        let grid = MultiviewGrid(channels: channels, capacity: 4, activeChannelId: nil)
        #expect(grid?.cells.first?.streamUrl == "http://127.0.0.1/10.ts")
    }

    @Test func emptyChannelsYieldsNil() {
        #expect(MultiviewGrid(channels: [], capacity: 4, activeChannelId: nil) == nil)
    }

    @Test func zeroCapacityYieldsNil() {
        #expect(MultiviewGrid(channels: channels, capacity: 0, activeChannelId: 10) == nil)
    }

    @Test func activeResolvesToMatchingChannel() {
        let grid = MultiviewGrid(channels: channels, capacity: 4, activeChannelId: 30)
        #expect(grid?.activeIndex == 2)
        #expect(grid?.activeCell?.id == 30)
    }

    @Test func activeFallsBackToFirstWhenNotPresent() {
        let grid = MultiviewGrid(channels: channels, capacity: 4, activeChannelId: 999)
        #expect(grid?.activeIndex == 0)
        #expect(grid?.activeCell?.id == 10)
    }

    @Test func addedAppendsWhenBelowCapacity() {
        let grid = MultiviewGrid(channels: [ch(10), ch(20)], capacity: 4, activeChannelId: nil)!
        let grown = grid.added(ch(30))
        #expect(grown.cells.map(\.id) == [10, 20, 30])
    }

    @Test func addedIsNoOpAtCapacity() {
        let grid = MultiviewGrid(channels: channels, capacity: 4, activeChannelId: nil)!
        #expect(grid.added(ch(50)) == grid)
    }

    @Test func addedIsNoOpOnDuplicate() {
        let grid = MultiviewGrid(channels: [ch(10), ch(20)], capacity: 4, activeChannelId: nil)!
        #expect(grid.added(ch(10)) == grid)
    }

    @Test func removedDropsTileAndReclampsActive() {
        var grid = MultiviewGrid(channels: channels, capacity: 4, activeChannelId: 40)!
        #expect(grid.activeIndex == 3)
        grid = grid.removed(at: 3)
        #expect(grid.cells.map(\.id) == [10, 20, 30])
        #expect(grid.activeIndex == 2)
    }

    @Test func removedKeepsAtLeastOne() {
        let grid = MultiviewGrid(channels: [ch(10)], capacity: 4, activeChannelId: nil)!
        #expect(grid.removed(at: 0) == grid)
    }

    @Test func removedIsNoOpForOutOfRange() {
        let grid = MultiviewGrid(channels: channels, capacity: 4, activeChannelId: nil)!
        #expect(grid.removed(at: 9) == grid)
    }

    @Test func withActiveClampsIntoRange() {
        let grid = MultiviewGrid(channels: channels, capacity: 4, activeChannelId: nil)!
        #expect(grid.withActive(2).activeIndex == 2)
        #expect(grid.withActive(99).activeIndex == 3)
        #expect(grid.withActive(-5).activeIndex == 0)
    }
}
