import Foundation

/// One tile in a channel's row strip: a half-open `[startMs, endMs)` time slot
/// that either carries a programme (`program != nil`) or is a "No information"
/// filler (`program == nil`). Kept View-free so both the airing test and the
/// layout maths are unit-testable headlessly. `ProgramEntity` is `Equatable`, so
/// `GuideCell`'s `Equatable` conformance is synthesised.
struct GuideCell: Equatable {
    let startMs: Int
    let endMs: Int
    let program: ProgramEntity?

    /// Whether this cell carries programme metadata (vs a filler slot).
    var hasInfo: Bool { program != nil }

    /// Whether `atMs` falls inside the cell, half-open: the start instant is
    /// contained, the end instant is not (so abutting cells never both match).
    func contains(_ atMs: Int) -> Bool {
        startMs <= atMs && atMs < endMs
    }
}
