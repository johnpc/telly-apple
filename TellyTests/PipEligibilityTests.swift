#if os(iOS)
import Testing
@testable import Telly

/// The pure PiP-slot eligibility decision: it requires OS/device support AND an
/// actively playing stream, and is false the moment either is missing.
struct PipEligibilityTests {
    @Test func supportedAndPlayingIsActionable() {
        #expect(PipEligibility.isActionable(isSupported: true, state: .playing))
    }

    @Test func unsupportedIsNotActionable() {
        #expect(!PipEligibility.isActionable(isSupported: false, state: .playing))
    }

    @Test func notPlayingIsNotActionable() {
        #expect(!PipEligibility.isActionable(isSupported: true, state: .buffering))
        #expect(!PipEligibility.isActionable(isSupported: true, state: .idle))
        #expect(!PipEligibility.isActionable(isSupported: true, state: .ended))
    }
}
#endif
