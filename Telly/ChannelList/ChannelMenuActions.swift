import Foundation

/// One row in the per-channel "Channel options" context menu — the Apple mirror
/// of the channel section (header = channel name) of Android's `PlayerMenu`. Of
/// that section's rows telly-apple offers the three it has built, in Android's
/// order: the favourite toggle, Hide, and Assign EPG. Android's "Block channel"
/// row is intentionally absent (the parental-block feature was removed) and its
/// "Channel options" sub-pane (rename / decoder / EPG-offset overrides) is not
/// yet ported; Copy-channels and multiview are all-channels / quick-bar actions
/// Android's channel section never carried, so they stay where they live.
enum ChannelMenuAction: Hashable {
    /// Add to / Remove from Favorites (the label flips on the channel's state).
    case toggleFavorite
    /// Hide the channel from the visible list (no "Show" toggle — un-hiding is a
    /// bulk Manage-Visibility action, exactly as on Android).
    case hide
    /// Open the per-channel Assign-EPG picker (the `epgOverride` editor).
    case assignEpg
}

/// The pure, View-free composition of the per-channel menu — the single source of
/// truth the row menu renders and the tests pin, so "which rows / what label for
/// a given channel state" is verified headlessly.
enum ChannelMenuActions {
    /// The ordered actions for `channel`, mirroring Android's per-channel section
    /// order (favourite toggle, Hide, Assign EPG). Constant today: every visible
    /// channel offers all three.
    static func actions(for channel: ChannelEntity) -> [ChannelMenuAction] {
        [.toggleFavorite, .hide, .assignEpg]
    }

    /// The row's label. The favourite row flips on the channel's current state —
    /// the mirror of Android `PlayerMenuItem.labelFor` ("Add to Favorites" ⇄
    /// "Remove from Favorites"); Hide and Assign EPG are fixed.
    static func label(_ action: ChannelMenuAction, for channel: ChannelEntity) -> String {
        switch action {
        case .toggleFavorite:
            return channel.flags.favorite ? "Remove from Favorites" : "Add to Favorites"
        case .hide:
            return "Hide channel"
        case .assignEpg:
            return "Assign EPG"
        }
    }
}
