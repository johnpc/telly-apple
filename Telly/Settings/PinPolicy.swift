import Foundation

/// The parental-PIN format rule, isolated so both the entry UI and the store
/// validate against one definition: a PIN is exactly four decimal digits.
enum PinPolicy {
    static let length = 4

    /// True iff `pin` is exactly ``length`` decimal digits.
    static func isValid(_ pin: String) -> Bool {
        pin.count == length && pin.allSatisfy(\.isNumber)
    }
}
