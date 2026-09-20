import Foundation

/// The pure, View-free rendering model for the program info panel: everything the
/// panel shows about one programme, derived from its ``ProgramEntity`` so the
/// SwiftUI layer only lays out strings. Air-time formatting reuses ``SearchAirTime``
/// (a bare range on the same day, date-prefixed on another); the timing badge,
/// genre chips and the description-or-empty decision are computed here so all are
/// unit-testable headlessly.
struct ProgramInfoPresentation: Equatable {
    let title: String
    let subtitle: String?
    let episode: String?
    let timeRange: String
    let timing: ProgramTiming
    let categories: [String]
    let description: String?

    /// True when there is synopsis text; false → the panel shows its empty state.
    var hasDescription: Bool { description != nil }

    /// Builds the presentation for `program` at `nowMs`. `timingOverride` lets the
    /// channel-detail block label the genuinely-next programme `.next` (which the
    /// boundary maths alone can't infer); the guide panel leaves it nil.
    static func make(program: ProgramEntity, nowMs: Int, timeZone: TimeZone,
                     timingOverride: ProgramTiming? = nil) -> ProgramInfoPresentation {
        let details = program.details
        return ProgramInfoPresentation(
            title: details.title,
            subtitle: nonBlank(details.subTitle),
            episode: nonBlank(details.episode),
            timeRange: SearchAirTime.text(program: program, atMs: nowMs, timeZone: timeZone),
            timing: timingOverride ?? ProgramTiming.of(
                startMs: program.startMs, endMs: program.endMs, nowMs: nowMs),
            categories: ProgramCategories.chips(from: details.category),
            description: nonBlank(details.description))
    }

    /// Trimmed text, or nil when the field is missing or all-whitespace.
    private static func nonBlank(_ text: String?) -> String? {
        guard let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty else { return nil }
        return trimmed
    }
}
