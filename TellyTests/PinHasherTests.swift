import Testing
@testable import Telly

/// The salted-SHA-256 PIN hasher: a correct PIN verifies, a wrong one doesn't,
/// distinct salts diverge, the digest is never the plaintext PIN, and the
/// constant-time comparator handles the empty, equal-length-mismatch and
/// unequal-length paths. A pinned vector proves Android `"$salt:$pin"` parity.
struct PinHasherTests {
    @Test func correctPinMatchesItsHash() {
        let salt = PinHasher.newSalt()
        let hash = PinHasher.hash(pin: "1234", salt: salt)
        #expect(PinHasher.matches(pin: "1234", salt: salt, expected: hash))
    }

    @Test func wrongPinDoesNotMatchEvenAtEqualLength() {
        let salt = PinHasher.newSalt()
        let hash = PinHasher.hash(pin: "1234", salt: salt)
        // Two digests are both 64 hex chars, so this exercises the reducer path.
        #expect(!PinHasher.matches(pin: "0000", salt: salt, expected: hash))
    }

    @Test func hashIsNeverThePlaintextPin() {
        let salt = PinHasher.newSalt()
        #expect(PinHasher.hash(pin: "1234", salt: salt) != "1234")
    }

    @Test func differentSaltsProduceDifferentHashesForTheSamePin() {
        let a = PinHasher.hash(pin: "1234", salt: PinHasher.newSalt())
        let b = PinHasher.hash(pin: "1234", salt: PinHasher.newSalt())
        #expect(a != b)
    }

    @Test func saltIsSixteenBytesOfLowercaseHex() {
        let salt = PinHasher.newSalt()
        #expect(salt.count == 32)   // 16 bytes → 32 hex chars
        #expect(salt.allSatisfy { $0.isHexDigit && !$0.isUppercase })
    }

    @Test func emptyExpectedNeverMatches() {
        let salt = PinHasher.newSalt()
        #expect(!PinHasher.matches(pin: "1234", salt: salt, expected: ""))
    }

    @Test func unequalLengthExpectedHitsTheLengthGuard() {
        let salt = PinHasher.newSalt()
        #expect(!PinHasher.matches(pin: "1234", salt: salt, expected: "abc"))
    }

    @Test func matchesAndroidPinnedVector() {
        // SHA-256("00000000000000000000000000000000:1234"), lowercase hex —
        // the exact format Android's PinHasher.kt produces (`"$salt:$pin"`).
        let salt = "00000000000000000000000000000000"
        let expected = "af88269895fea9e985d8e7587268ea2fd6d0a639cc0438c88a9b22d6ce96b3ba"
        #expect(PinHasher.hash(pin: "1234", salt: salt) == expected)
        #expect(expected.count == 64)
        #expect(PinHasher.matches(pin: "1234", salt: salt, expected: expected))
        #expect(!PinHasher.matches(pin: "1235", salt: salt, expected: expected))
    }
}
