import Testing
@testable import Telly

/// The pure live-transport control model: clamped focus movement across the row
/// and each control's activation command. Live is never seekable, so no control
/// maps to a seek — channel change routes through the coalesced `.zap`.
struct LiveTransportButtonTests {
    @Test func rowOrderIsChannelDownPlayPauseChannelUp() {
        #expect(LiveTransportButton.allCases == [.channelDown, .playPause, .channelUp])
    }

    @Test func movesRightWithinTheRow() {
        #expect(LiveTransportButton.channelDown.moved(by: 1) == .playPause)
        #expect(LiveTransportButton.playPause.moved(by: 1) == .channelUp)
    }

    @Test func movesLeftWithinTheRow() {
        #expect(LiveTransportButton.channelUp.moved(by: -1) == .playPause)
        #expect(LiveTransportButton.playPause.moved(by: -1) == .channelDown)
    }

    @Test func clampsAtBothEndsNoWrap() {
        #expect(LiveTransportButton.channelDown.moved(by: -1) == .channelDown)  // left end holds
        #expect(LiveTransportButton.channelUp.moved(by: 1) == .channelUp)       // right end holds
        #expect(LiveTransportButton.channelDown.moved(by: 5) == .channelUp)     // saturates
    }

    @Test func playPauseTogglesPlayback() {
        #expect(LiveTransportButton.playPause.command == .togglePlayPause)
    }

    @Test func channelControlsMapToZapDeltas() {
        #expect(LiveTransportButton.channelUp.command == .zap(delta: 1))
        #expect(LiveTransportButton.channelDown.command == .zap(delta: -1))
    }
}
