import Testing
@testable import Telly

/// The pure past-cell catch-up gate: filler/airing/future/no-capability/
/// out-of-horizon all report false; a real aired cell within the channel's
/// `catchup-days` window (inclusive of the horizon boundary) reports true.
struct CatchupPlayabilityTests {
    static let now = 1_000_000_000_000
    static let dayMs = 24 * 3_600_000

    /// A channel with a working `default` catch-up source (7-day horizon).
    private func catchupChannel(days: Int? = nil) -> ChannelEntity {
        ChannelEntity(
            playlistId: 1, number: 1, sortIndex: 0,
            source: ChannelSource(name: "c", streamUrl: "http://x", tvgId: "c"),
            catchup: ChannelCatchup(catchupType: "default",
                                    catchupSource: "http://x/archive?utc=${start}",
                                    catchupDays: days))
    }

    /// A channel that declares no catch-up capability at all.
    private func plainChannel() -> ChannelEntity {
        ChannelEntity(playlistId: 1, number: 1, sortIndex: 0,
                      source: ChannelSource(name: "c", streamUrl: "http://x", tvgId: "c"))
    }

    private func playable(_ channel: ChannelEntity, start: Int, end: Int,
                          hasInfo: Bool = true) -> Bool {
        CatchupPlayability.playable(channel: channel, startMs: start, endMs: end,
                                    hasInfo: hasInfo, nowMs: Self.now)
    }

    @Test func fillerCellIsNotPlayable() {
        #expect(!playable(catchupChannel(), start: Self.now - 3_600_000,
                          end: Self.now - 1_800_000, hasInfo: false))
    }

    @Test func airingCellIsNotPlayable() {
        // endMs > nowMs → still airing.
        #expect(!playable(catchupChannel(), start: Self.now - 1_800_000,
                          end: Self.now + 1_800_000))
    }

    @Test func futureCellIsNotPlayable() {
        #expect(!playable(catchupChannel(), start: Self.now + 1_800_000,
                          end: Self.now + 3_600_000))
    }

    @Test func channelWithoutCapabilityIsNotPlayable() {
        #expect(!playable(plainChannel(), start: Self.now - 3_600_000, end: Self.now - 1_800_000))
    }

    @Test func cellOlderThanHorizonIsNotPlayable() {
        let start = Self.now - 7 * Self.dayMs - 1  // one ms past the 7-day window
        #expect(!playable(catchupChannel(), start: start, end: start + 1_800_000))
    }

    @Test func recentlyAiredCellWithinWindowIsPlayable() {
        #expect(playable(catchupChannel(), start: Self.now - 5_400_000, end: Self.now - 1_800_000))
    }

    @Test func horizonBoundaryIsPlayable() {
        let start = Self.now - 7 * Self.dayMs  // exactly on the horizon → inclusive
        #expect(playable(catchupChannel(), start: start, end: start + 1_800_000))
    }
}
