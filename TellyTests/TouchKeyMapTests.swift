import Testing
@testable import Telly

/// Exhaustive (gesture × overlay) → key table for ``TouchKeyMap``: a tap opens
/// info only at bare playback and otherwise emits `.back` (so a tap never exits
/// to the guide); the four swipes map to fixed keys regardless of the overlay.
struct TouchKeyMapTests {
    /// Every overlay a tap can land on while chrome is up — each must emit `.back`.
    static let overlaysWithChrome: [PlaybackOverlay] = [
        .info, .infoTransport, .zapInfo, .quickBar, .panel,
        .channelMenu(channelId: 7), .pushed(back: .panel),
    ]

    @Test func tapAtBarePlaybackEmitsOk() {
        #expect(TouchKeyMap.key(for: .tap, overlay: .none) == .ok)
    }

    @Test(arguments: overlaysWithChrome)
    func tapWithOverlayEmitsBack(_ overlay: PlaybackOverlay) {
        #expect(TouchKeyMap.key(for: .tap, overlay: overlay) == .back)
    }

    struct SwipeCase: Sendable {
        let gesture: TouchGesture
        let key: PlaybackKey
    }
    static let swipes = [
        SwipeCase(gesture: .swipeUp, key: .channelUp),
        SwipeCase(gesture: .swipeDown, key: .channelDown),
        SwipeCase(gesture: .swipeLeft, key: .left),
        SwipeCase(gesture: .swipeRight, key: .right),
    ]
    static let allOverlays: [PlaybackOverlay] = [.none] + overlaysWithChrome

    @Test(arguments: swipes, allOverlays)
    func swipeMapsIndependentOfOverlay(_ c: SwipeCase, _ overlay: PlaybackOverlay) {
        #expect(TouchKeyMap.key(for: c.gesture, overlay: overlay) == c.key)
    }
}
