import CryptoKit
import Foundation

/// Salted SHA-256 hashing for the parental-controls PIN, byte-for-byte the same
/// format as the Android app's `PinHasher.kt` — `SHA-256("$salt:$pin")` over a
/// 16-byte random salt, lowercase hex — so a hash is portable between the two.
/// The raw PIN is never persisted; only its salted digest is, and verification
/// runs in constant time.
enum PinHasher {
    private static let saltBytes = 16

    /// A fresh 16-byte cryptographic salt, lowercase hex (32 characters).
    static func newSalt() -> String {
        var bytes = [UInt8](repeating: 0, count: saltBytes)
        _ = SecRandomCopyBytes(kSecRandomDefault, saltBytes, &bytes)
        return hex(bytes)
    }

    /// The lowercase-hex SHA-256 of `"salt:pin"` (Android `hash(pin, salt)`).
    static func hash(pin: String, salt: String) -> String {
        hex(Array(SHA256.hash(data: Data("\(salt):\(pin)".utf8))))
    }

    /// Verifies `pin` against a stored digest. Empty `expected` → false (matches
    /// Android); otherwise re-hash and compare in constant time.
    static func matches(pin: String, salt: String, expected: String) -> Bool {
        guard !expected.isEmpty else { return false }
        return constantTimeEqual(hash(pin: pin, salt: salt), expected)
    }

    /// Lowercase hex of a byte sequence.
    private static func hex(_ bytes: [UInt8]) -> String {
        bytes.map { String(format: "%02x", $0) }.joined()
    }

    /// Branch-free equality after a length precheck — CryptoKit's `Digest ==`
    /// is not documented timing-safe, so we OR every XORed byte pair and test
    /// the accumulator once (no early-out on the first differing byte).
    private static func constantTimeEqual(_ lhs: String, _ rhs: String) -> Bool {
        let a = Array(lhs.utf8), b = Array(rhs.utf8)
        guard a.count == b.count else { return false }
        return zip(a, b).reduce(UInt8(0)) { $0 | ($1.0 ^ $1.1) } == 0
    }
}
