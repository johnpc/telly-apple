import Testing
@testable import Telly

/// The four-digit PIN format rule: exactly four decimal digits pass; anything
/// too short, too long, or non-numeric (including a leading space) is rejected.
struct PinPolicyTests {
    @Test func fourDigitsAreValid() {
        #expect(PinPolicy.isValid("1234"))
    }

    @Test(arguments: ["", "12", "12345", "12a4", " 123"])
    func nonFourDigitStringsAreRejected(_ pin: String) {
        #expect(!PinPolicy.isValid(pin))
    }
}
