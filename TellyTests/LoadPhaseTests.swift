import Testing
@testable import Telly

/// The pure terminal-phase resolver: cached content always wins, an empty
/// successful load is `empty`, an empty failed one is `failed`.
struct LoadPhaseTests {
    @Test func contentAlwaysResolvesLoaded() {
        #expect(LoadPhaseResolver.resolve(hasContent: true, failed: false) == .loaded)
        #expect(LoadPhaseResolver.resolve(hasContent: true, failed: true) == .loaded)
    }

    @Test func emptySuccessIsEmpty() {
        #expect(LoadPhaseResolver.resolve(hasContent: false, failed: false) == .empty)
    }

    @Test func emptyFailureIsFailed() {
        #expect(LoadPhaseResolver.resolve(hasContent: false, failed: true) == .failed)
    }
}
