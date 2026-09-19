import SwiftUI
import Testing
@testable import Telly

/// The pure channel-list layout decisions: which size class earns the iPad
/// split, and the detail pane's selected-channel resolution (matched id, first
/// -row fallback, empty). View geometry is left to the visual capture.
struct ChannelListLayoutTests {
    private func ch(_ id: Int) -> ChannelEntity {
        ChannelEntity(id: id, playlistId: 1, number: id, sortIndex: id,
                      source: ChannelSource(name: "Ch\(id)", groupTitle: "Live",
                                            streamUrl: "http://127.0.0.1/\(id).ts"))
    }

    @Test func regularWidthUsesSplit() {
        #expect(ChannelListLayout.usesSplit(.regular) == true)
    }

    @Test func compactWidthStaysStacked() {
        #expect(ChannelListLayout.usesSplit(.compact) == false)
    }

    @Test func unknownSizeClassStaysStacked() {
        #expect(ChannelListLayout.usesSplit(nil) == false)
    }

    @Test func selectedChannelMatchesId() {
        let rows = [ch(1), ch(2), ch(3)]
        #expect(ChannelListLayout.selectedChannel(in: rows, id: 2) == ch(2))
    }

    @Test func selectedChannelFallsBackToFirstWhenIdMissing() {
        let rows = [ch(4), ch(5)]
        #expect(ChannelListLayout.selectedChannel(in: rows, id: 99) == ch(4))
    }

    @Test func selectedChannelFallsBackToFirstWhenNoSelection() {
        let rows = [ch(7), ch(8)]
        #expect(ChannelListLayout.selectedChannel(in: rows, id: nil) == ch(7))
    }

    @Test func selectedChannelIsNilWhenNoRows() {
        #expect(ChannelListLayout.selectedChannel(in: [], id: 1) == nil)
    }
}
