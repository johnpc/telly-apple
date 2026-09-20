import Foundation

/// One row of the per-pane menu opened by OK on a multiview tile (Android's
/// OK-on-pane semantics): change the pane's channel, promote it to fullscreen,
/// remove it, or add another pane. `removePane`/`addPane` are conditional on the
/// live pane count vs capacity, so the row set is a pure function of both.
enum MultiviewMenuRow: Equatable, Sendable {
    case changeChannel
    case fullscreen
    case removePane
    case addPane

    /// The row's user-facing label.
    var title: String {
        switch self {
        case .changeChannel: return "Change channel"
        case .fullscreen: return "Fullscreen"
        case .removePane: return "Remove pane"
        case .addPane: return "Add pane"
        }
    }

    /// The SF Symbol drawn beside the label.
    var symbol: String {
        switch self {
        case .changeChannel: return "arrow.left.arrow.right"
        case .fullscreen: return "arrow.up.left.and.arrow.down.right"
        case .removePane: return "minus.square"
        case .addPane: return "plus.square"
        }
    }
}

/// Pure pane-menu composition: the visible rows for a grid of `paneCount` tiles
/// capped at `capacity`. Change/Fullscreen are always offered; Remove appears
/// only above one pane, Add only below capacity — Android's pane-menu semantics.
enum MultiviewMenu {
    static func rows(paneCount: Int, capacity: Int) -> [MultiviewMenuRow] {
        var rows: [MultiviewMenuRow] = [.changeChannel, .fullscreen]
        if paneCount > 1 { rows.append(.removePane) }
        if paneCount < capacity { rows.append(.addPane) }
        return rows
    }
}

/// Which channel-picker intent is open over a pane menu: replacing the active
/// pane's channel, or adding a new pane.
enum MultiviewPickerMode: Equatable, Sendable {
    case change, add

    /// The picker's dialog title for each intent.
    var title: String { self == .change ? "Change channel" : "Add pane" }
}

/// The pane-menu interaction state: which row is highlighted.
struct MultiviewPaneMenu: Equatable { var selection = 0 }

/// The channel-picker interaction state: its intent and highlighted row.
struct MultiviewPicker: Equatable {
    let mode: MultiviewPickerMode
    var selection = 0
}
