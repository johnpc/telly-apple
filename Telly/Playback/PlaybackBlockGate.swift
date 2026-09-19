import Foundation

/// The tune-time parental gate for the fullscreen player — Apple's port of
/// Android `BlockGate`. It sits in front of every tune (zap / panel select /
/// cold-start restore) and, when the target channel `mustChallenge`, stores it
/// as `pending` so the screen can raise the reused ``PinChallengeSheetView``
/// over the video instead of loading the stream. The PIN itself never flows
/// through here: `unlock` delegates straight to ``ParentalStore/verify(pin:)``
/// (Keychain + salted hash + constant-time compare) and is never logged.
///
/// Per D1 the gate re-prompts on EVERY blocked tune (no relock/session bit);
/// the only carry-over is `passOnceId`, which lets the just-unlocked channel's
/// immediate tune pass through exactly once so unlocking actually plays it.
@MainActor
@Observable
final class PlaybackBlockGate {
    @ObservationIgnored let parental: ParentalStore
    /// The channel awaiting a PIN, or nil when nothing is challenged. The screen
    /// renders the challenge iff this is non-nil.
    var pending: ChannelEntity?
    /// The id allowed through `intercept` exactly once after a successful unlock.
    @ObservationIgnored private var passOnceId: Int?

    init(parental: ParentalStore) { self.parental = parental }

    /// True when `channel` must be PIN-challenged before it tunes (and records it
    /// as `pending`); false lets the tune proceed. The just-unlocked channel is
    /// waved through once via `passOnceId`.
    func intercept(_ channel: ChannelEntity) -> Bool {
        if passOnceId == channel.id { passOnceId = nil; return false }
        guard parental.mustChallenge(channel) else { return false }
        pending = channel
        return true
    }

    /// Verifies `pin` against the stored credential; on success arms the one-shot
    /// pass and returns the channel to tune, else returns nil (keeps prompting).
    func unlock(pin: String) -> ChannelEntity? {
        guard parental.verify(pin: pin), let channel = pending else { return nil }
        passOnceId = channel.id
        pending = nil
        return channel
    }

    /// A pure blocked check (no `pending` side effect) so multiview can keep a
    /// blocked non-active tile from decoding without raising a challenge for it.
    func blocks(_ channel: ChannelEntity) -> Bool { parental.mustChallenge(channel) }

    /// Clears the prompt without tuning (Cancel).
    func dismiss() { pending = nil }
}
