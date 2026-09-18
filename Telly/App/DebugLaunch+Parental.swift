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

    /// Whether to launch the fullscreen player with its first channel blocked and
    /// an enabled seeded PIN — set by `-tellyPlaybackBlock` — so the block-PIN
    /// overlay is forced over the black stage for the playback-gate proof.
    static func playbackBlockRequested(in args: [String]) -> Bool {
        args.contains("-tellyPlaybackBlock")
    }

    /// Marks the first visible fixture channel blocked and seeds + enables `pin`,
    /// so the challenge proof has a locked channel with an active credential.
    /// Idempotent (safe to relaunch); a no-op when there are no channels.
    @MainActor
    static func seedParentalBlock(into store: ChannelStore, parental: ParentalStore, pin: String) {
        guard let first = (try? store.visibleChannels())?.first else { return }
        var blocked = first
        blocked.flags.blocked = true
        try? store.update(blocked)
        parental.set(pin: pin)
        parental.isEnabled = true
    }
}
#endif
