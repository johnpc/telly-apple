import Foundation

/// What OK does at bare fullscreen playback (Android `PlayerOkAction`).
enum PlayerOkAction: Int, CaseIterable {
    case showInfo = 0
    case channelsList = 1
    case nothing = 2

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
enum PlayerUpDownAction: Int, CaseIterable {
    case showInfo = 0
    case switchChannels = 1
    case nothing = 2

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
enum PlayerLeftRightAction: Int, CaseIterable {
    case nothing = 0
    case switchChannels = 1

    /// RIGHT zaps forward (+1), LEFT back (-1); `nil` = the key does nothing.
    func command(_ delta: Int) -> PlaybackCommand? {
        self == .switchChannels ? .zap(delta: delta) : nil
    }
}

/// What a held OK does (MENU stays the quick-menu key). Android `PlayerLongOkAction`.
enum PlayerLongOkAction: Int, CaseIterable {
    case quickMenu = 0
    case channelsList = 1

    /// The command long-OK emits (always bound).
    var command: PlaybackCommand {
        self == .quickMenu ? .openQuickBar : .openPanel
    }
}

/// The remappable fullscreen-playback keys (Android `PlayerKeymap`). Each action
/// enum is an `Int`-backed `CaseIterable` choice (see `PlayerKeymapChoices.swift`
/// for the display titles) and derives from stored raw values via
/// `PlayerKeymap.from(okRaw:upDownRaw:leftRightRaw:longOkRaw:)`
/// (`PlayerKeymap+Derivation.swift`). The `from(settings:)` adapter that reads
/// those raws out of `SettingsStore` lands with the settings slice. No
/// tvOS-specific variant yet — that arrives in a later slice.
struct PlayerKeymap {
    var ok: PlayerOkAction = .showInfo
    var upDown: PlayerUpDownAction = .showInfo
    var leftRight: PlayerLeftRightAction = .nothing
    var longOk: PlayerLongOkAction = .quickMenu
}
