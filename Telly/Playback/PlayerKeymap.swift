import Foundation

/// What OK does at bare fullscreen playback (Android `PlayerOkAction`).
enum PlayerOkAction {
    case showInfo
    case channelsList
    case nothing

    /// The command OK emits, or `nil` when the key is unbound.
    var command: PlaybackCommand? {
        switch self {
        case .showInfo: return .showInfo
        case .channelsList: return .openPanel
        case .nothing: return nil
        }
    }
}

/// What UP/DOWN do at bare fullscreen playback (Android `PlayerUpDownAction`).
enum PlayerUpDownAction {
    case showInfo
    case switchChannels
    case nothing

    /// UP zaps forward (+1), DOWN back (-1); `nil` = the key does nothing.
    func command(_ delta: Int) -> PlaybackCommand? {
        switch self {
        case .showInfo: return .showInfo
        case .switchChannels: return .zap(delta: delta)
        case .nothing: return nil
        }
    }
}

/// What LEFT/RIGHT do at bare fullscreen playback (no-ops by default).
enum PlayerLeftRightAction {
    case nothing
    case switchChannels

    /// RIGHT zaps forward (+1), LEFT back (-1); `nil` = the key does nothing.
    func command(_ delta: Int) -> PlaybackCommand? {
        self == .switchChannels ? .zap(delta: delta) : nil
    }
}

/// What a held OK does (MENU stays the quick-menu key). Android `PlayerLongOkAction`.
enum PlayerLongOkAction {
    case quickMenu
    case channelsList

    /// The command long-OK emits (always bound).
    var command: PlaybackCommand {
        self == .quickMenu ? .openQuickBar : .openPanel
    }
}

/// The remappable fullscreen-playback keys (Android `PlayerKeymap`). Only the
/// device-verified defaults are ported; Android's `from(settings:)` constructor
/// and the `KeymapChoice` / `keymapChoice` label plumbing are omitted until the
/// settings slice lands (they would be dead code here). No tvOS-specific variant
/// yet — that arrives in a later slice.
struct PlayerKeymap {
    var ok: PlayerOkAction = .showInfo
    var upDown: PlayerUpDownAction = .showInfo
    var leftRight: PlayerLeftRightAction = .nothing
    var longOk: PlayerLongOkAction = .quickMenu
}
