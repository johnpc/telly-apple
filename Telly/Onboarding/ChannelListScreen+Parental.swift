import SwiftUI

/// The parental-lock wiring for ``ChannelListScreen``, split out to keep the
/// screen within the source-line budget (mirrors the `+Toolbar` split). Holds
/// the channel row (whose tap is PIN-gated for blocked channels), the Lock /
/// Unlock context-menu action, and the challenge / lock-confirmation sheets.
/// Security invariant: a wrong or cancelled PIN never sets `target`, so a locked
/// channel never tunes without the correct PIN.
extension ChannelListScreen {
    @ViewBuilder func row(_ channel: ChannelEntity) -> some View {
        Button { tapped(channel) } label: { ChannelListRowView(channel: channel) }
            .buttonStyle(.plain)
            .contextMenu {
                Button(channel.flags.favorite ? "Remove Favorite" : "Add to Favorites") {
                    model.toggleFavorite(channel)
                }
                Button(channel.flags.blocked ? "Unlock Channel" : "Lock Channel") {
                    lockTarget = ParentalChannelBox(channel: channel)
                }
                Button("Hide channel", role: .destructive) { model.hide(channel) }
            }
    }

    /// A row tunes directly unless it is a locked channel with an active PIN —
    /// then the challenge sheet is presented instead of setting the target.
    private func tapped(_ channel: ChannelEntity) {
        if parental.mustChallenge(channel) {
            challenge = ParentalChannelBox(channel: channel)
        } else {
            target = PlaybackTarget(id: channel.id, url: channel.source.streamUrl)
        }
    }

    /// Unlock-to-tune: a correct PIN sets the playback target (the channel tunes);
    /// a wrong or cancelled PIN leaves it nil, so the channel never tunes.
    @ViewBuilder func challengeSheet(_ channel: ChannelEntity) -> some View {
        PinChallengeSheetView { pin in
            guard parental.verify(pin: pin) else { return false }
            target = PlaybackTarget(id: channel.id, url: channel.source.streamUrl)
            return true
        }
    }

    /// Lock/unlock confirmation (Android `ChannelBlocker`): with no PIN yet the
    /// Set-PIN sheet runs first; otherwise the current PIN is confirmed. Either
    /// way, success flips and persists the channel's blocked flag.
    @ViewBuilder func lockSheet(_ channel: ChannelEntity) -> some View {
        if parental.isSet {
            PinChallengeSheetView { flip(channel, ifPin: parental.verify(pin: $0)) }
        } else {
            PinEntrySheetView(mode: .set) { flip(channel, ifPin: parental.set(pin: $0)) }
        }
    }

    private func flip(_ channel: ChannelEntity, ifPin accepted: Bool) -> Bool {
        guard accepted else { return false }
        model.setBlocked(channel, !channel.flags.blocked)
        return true
    }
}
