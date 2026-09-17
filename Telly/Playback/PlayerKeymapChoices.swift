import Foundation

/// A remappable player key choice (Android `KeymapChoice`): an `Int`-backed
/// enumerable option with a human-readable title for the settings picker. The
/// raw values are stable and never reordered so persisted choices stay valid.
protocol PlayerKeymapChoice: CaseIterable, RawRepresentable where RawValue == Int {
    var title: String { get }
}

extension PlayerOkAction: PlayerKeymapChoice {
    var title: String {
        switch self {
        case .showInfo: return "Show info panel"
        case .channelsList: return "Open channels list"
        case .nothing: return "Nothing"
        }
    }
}

extension PlayerUpDownAction: PlayerKeymapChoice {
    var title: String {
        switch self {
        case .showInfo: return "Show info panel"
        case .switchChannels: return "Switch channels"
        case .nothing: return "Nothing"
        }
    }
}

extension PlayerLeftRightAction: PlayerKeymapChoice {
    var title: String {
        switch self {
        case .nothing: return "Nothing"
        case .switchChannels: return "Switch channels"
        }
    }
}

extension PlayerLongOkAction: PlayerKeymapChoice {
    var title: String {
        switch self {
        case .quickMenu: return "Open quick menu"
        case .channelsList: return "Open channels list"
        }
    }
}
