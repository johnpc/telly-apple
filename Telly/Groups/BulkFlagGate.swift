import Foundation

/// The pure entry-gate for the bulk "Manage blocking" editor — the Apple port of
/// Android `BulkFlagSession.gated()`. The BLOCKING editor is locked on entry
/// (demanding the parental PIN) only when parental enforcement is enabled AND a
/// PIN has actually been set; the VISIBILITY editor is never gated, so it has no
/// gate at all. Leaf: no dependencies, no I/O.
enum BulkFlagGate {
    /// True when the blocking editor must be PIN-unlocked before it can be used.
    static func locked(isEnabled: Bool, isSet: Bool) -> Bool {
        isEnabled && isSet
    }
}
