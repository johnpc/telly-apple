import Foundation

/// Pure decision for the guide overlay's live mini-player inset. TiviMate keeps a
/// corner preview of the playing channel while you browse the EPG; we surface it
/// on the roomy platforms — Apple TV and regular-width iPad — and omit it in the
/// compact iPhone width, where the guide takes the whole screen (the audit's
/// iPad-regular / tvOS focus). Kept pure so the rule is unit-tested, not the view.
enum MiniPlayerPlacement {
    /// Whether the mini-player inset is shown. Apple TV (`tv`) always shows it;
    /// otherwise it needs a regular-width canvas (`compact == false`).
    static func shown(compact: Bool, tv: Bool) -> Bool {
        tv || !compact
    }
}
