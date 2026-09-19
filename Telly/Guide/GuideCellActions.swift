import Foundation

/// A programme action a guide cell's menu offers, pared to what telly ships.
/// Android's cell dropdown (`GuideScreenCellMenu`, capture 27) lists Remind /
/// Record / Custom recording / Add to My list / Program description; reminders
/// and DVR are tabled on Apple, so the only live action is the My List toggle.
enum GuideProgramAction: Equatable {
    /// Add to / Remove from My List (the label flips on saved state at render).
    case myList
}

/// The pure "which programme actions does this cell offer" decision, kept
/// View-free so it is unit-testable headlessly.
enum GuideCellActions {
    /// The actions offered for `cell`: the My List toggle when it carries a
    /// programme, nothing for a "No information" filler slot.
    static func actions(for cell: GuideCell) -> [GuideProgramAction] {
        cell.hasInfo ? [.myList] : []
    }
}
