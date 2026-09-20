import Foundation

/// A programme action the info panel offers for a cell, chosen by its activation
/// outcome (``GuideSelection``): an airing cell plays live, a catch-up-eligible
/// past cell plays the archive, and any other info-carrying cell offers the My
/// List toggle. The Apple mirror of Android's cell dropdown, pared to what telly
/// ships (Remind / Record remain tabled).
enum GuideProgramAction: Equatable {
    /// Tune the channel's live stream (the cell is airing now).
    case watch
    /// Play the channel's catch-up archive (a past, catch-up-eligible cell).
    case catchup
    /// Add to / Remove from My List (the label flips on saved state at render).
    case myList

    /// The prominent play button's title, or nil for the My List toggle (whose
    /// label flips on saved state via ``MyListToggle`` instead). Kept on the enum
    /// so the action view stays a thin `if let` fork rather than a nested switch.
    var playTitle: String? {
        switch self {
        case .watch: return "Watch"
        case .catchup: return "Watch from start"
        case .myList: return nil
        }
    }

    /// The play button's SF Symbol (catch-up rewinds; live plays).
    var playIcon: String {
        switch self {
        case .catchup: return "arrow.counterclockwise"
        case .watch, .myList: return "play.fill"
        }
    }
}

/// The pure "which action does this cell's info panel offer" decision, kept
/// View-free so it is unit-testable headlessly. A filler slot (`.none`) offers
/// nothing and never opens the panel.
enum GuideCellActions {
    static func actions(for selection: GuideSelection) -> [GuideProgramAction] {
        switch selection {
        case .tune: return [.watch]
        case .catchup: return [.catchup]
        case .info: return [.myList]
        case .none: return []
        }
    }
}
