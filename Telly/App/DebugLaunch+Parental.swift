#if DEBUG
import Foundation

/// DEBUG-only launch flags for the parental-controls proofs, kept out of the
/// 99-line `DebugLaunch` core (the `+Settings`/`+Channels` precedent). Slice 3
/// ships only the flag parsers the Slice-4 challenge-sheet proof will drive;
/// Slice 4 extends this with the seeding that marks a fixture channel blocked,
/// writes the seed PIN through the ``ParentalStore``, and forces the challenge
/// sheet over the channel list. Every helper takes its `args` explicitly.
extension DebugLaunch {
    /// Whether to force the locked-channel PIN challenge over the channel list
    /// instead of tuning — set by `-tellyParentalChallenge`. Slice 4 acts on it.
    static func parentalChallengeRequested(in args: [String]) -> Bool {
        args.contains("-tellyParentalChallenge")
    }

    /// The PIN to pre-seed for the challenge proof (`-tellyParentalPin 1234`), or
    /// nil to leave no PIN set. Slice 4 writes it through the ``ParentalStore``.
    static func seedParentalPin(in args: [String]) -> String? {
        value(for: "-tellyParentalPin", in: args)
    }
}
#endif
