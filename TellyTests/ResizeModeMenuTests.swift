import Testing
@testable import Telly

/// The pure aspect-ratio picker choices: the offered modes, their labels, the
/// rows (with the active one checked) and the id↔mode round-trip.
struct ResizeModeMenuTests {
    @Test func selectableModesAreTheTiviMateSet() {
        #expect(ResizeMode.selectable == [.fit, .fill, .ratio16x9, .ratio4x3, .zoom])
    }

    @Test func titlesMatchTheControlNames() {
        #expect(ResizeMode.selectable.map(\.title) == ["Fit", "Fill", "16:9", "4:3", "Zoom"])
    }

    @Test func rowsCheckTheSelectedMode() {
        let rows = ResizeModeChoices.rows(selected: .ratio16x9)
        #expect(rows.map(\.label) == ["Fit", "Fill", "16:9", "4:3", "Zoom"])
        #expect(rows.first(where: \.checked)?.label == "16:9")
        #expect(rows.filter(\.checked).count == 1)
    }

    @Test func idRoundTripsToTheMode() {
        for mode in ResizeMode.selectable {
            let id = ResizeModeChoices.rows(selected: mode).first(where: \.checked)?.id
            #expect(ResizeModeChoices.mode(forId: id ?? "") == mode)
        }
    }

    @Test func unknownOrNonSelectableIdIsNil() {
        #expect(ResizeModeChoices.mode(forId: "nonsense") == nil)
        #expect(ResizeModeChoices.mode(forId: "") == nil)
        // fixedWidth has a valid raw value but is not an offered choice.
        #expect(ResizeModeChoices.mode(forId: String(ResizeMode.fixedWidth.rawValue)) == nil)
    }
}
