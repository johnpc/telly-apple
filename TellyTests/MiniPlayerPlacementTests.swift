import Testing
@testable import Telly

/// The mini-player inset visibility rule: shown on Apple TV and regular-width
/// iPad, hidden in the compact iPhone width where the guide takes the screen.
struct MiniPlayerPlacementTests {
    @Test func appleTvAlwaysShowsInset() {
        #expect(MiniPlayerPlacement.shown(compact: true, tv: true))
        #expect(MiniPlayerPlacement.shown(compact: false, tv: true))
    }

    @Test func regularWidthShowsInset() {
        #expect(MiniPlayerPlacement.shown(compact: false, tv: false))
    }

    @Test func compactHidesInset() {
        #expect(!MiniPlayerPlacement.shown(compact: true, tv: false))
    }
}
