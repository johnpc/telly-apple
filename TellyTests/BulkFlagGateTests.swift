import Testing
@testable import Telly

/// The pure bulk-flag entry gate (Android `BulkFlagSession.gated()`): the
/// blocking editor is locked only when parental enforcement is enabled AND a PIN
/// is set — all four combinations are exercised.
struct BulkFlagGateTests {
    @Test func lockedOnlyWhenEnabledAndPinSet() {
        #expect(BulkFlagGate.locked(isEnabled: true, isSet: true) == true)
    }

    @Test func unlockedWhenEnabledButNoPin() {
        #expect(BulkFlagGate.locked(isEnabled: true, isSet: false) == false)
    }

    @Test func unlockedWhenPinSetButDisabled() {
        #expect(BulkFlagGate.locked(isEnabled: false, isSet: true) == false)
    }

    @Test func unlockedWhenNeither() {
        #expect(BulkFlagGate.locked(isEnabled: false, isSet: false) == false)
    }
}
