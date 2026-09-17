import Testing
@testable import Telly

/// Wrap-around channel adjacency math and last-watched restore.
struct ChannelZapperTests {
    private func channel(_ id: Int) -> ChannelEntity {
        ChannelEntity(id: id, playlistId: 1, number: id, sortIndex: id,
                      source: ChannelSource(name: "Ch\(id)", streamUrl: "s\(id)"))
    }
    private var channels: [ChannelEntity] { [channel(10), channel(20), channel(30)] }

    @Test func neighbourStepsForward() {
        #expect(ChannelZapper.neighbour(channels, current: channel(10), delta: 1)?.id == 20)
    }

    @Test func neighbourStepsBackward() {
        #expect(ChannelZapper.neighbour(channels, current: channel(20), delta: -1)?.id == 10)
    }

    @Test func neighbourWrapsForwardAtEnd() {
        #expect(ChannelZapper.neighbour(channels, current: channel(30), delta: 1)?.id == 10)
    }

    @Test func neighbourWrapsBackwardAtStart() {
        // Proves floor-modulo: -1 from index 0 must land on the last channel.
        #expect(ChannelZapper.neighbour(channels, current: channel(10), delta: -1)?.id == 30)
    }

    @Test func neighbourMultiStep() {
        #expect(ChannelZapper.neighbour(channels, current: channel(10), delta: 2)?.id == 30)
        #expect(ChannelZapper.neighbour(channels, current: channel(10), delta: 3)?.id == 10)
    }

    @Test func neighbourEmptyListIsNil() {
        #expect(ChannelZapper.neighbour([], current: channel(10), delta: 1) == nil)
    }

    @Test func neighbourSingleChannelReturnsItself() {
        #expect(ChannelZapper.neighbour([channel(10)], current: channel(10), delta: 1)?.id == 10)
        #expect(ChannelZapper.neighbour([channel(10)], current: channel(10), delta: -1)?.id == 10)
    }

    @Test func neighbourAbsentCurrentReturnsFirst() {
        #expect(ChannelZapper.neighbour(channels, current: nil, delta: 1)?.id == 10)
        #expect(ChannelZapper.neighbour(channels, current: channel(99), delta: 1)?.id == 10)
    }

    @Test func restoreReturnsLastWatchedWhenPresent() {
        #expect(ChannelZapper.restore(channels, lastChannelId: 20)?.id == 20)
    }

    @Test func restoreFallsBackToFirst() {
        #expect(ChannelZapper.restore(channels, lastChannelId: 99)?.id == 10)
        #expect(ChannelZapper.restore(channels, lastChannelId: nil)?.id == 10)
    }

    @Test func restoreEmptyIsNil() {
        #expect(ChannelZapper.restore([], lastChannelId: 10) == nil)
    }
}
