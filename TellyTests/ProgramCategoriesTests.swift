import Testing
@testable import Telly

/// The pure genre-chip split: mixed delimiters, trimming, case-insensitive
/// de-duplication, and empty/absent fields yielding no chips.
struct ProgramCategoriesTests {
    @Test func nilYieldsNoChips() {
        #expect(ProgramCategories.chips(from: nil).isEmpty)
    }

    @Test func blankYieldsNoChips() {
        #expect(ProgramCategories.chips(from: "   ").isEmpty)
    }

    @Test func singleCategoryIsOneChip() {
        #expect(ProgramCategories.chips(from: "Drama") == ["Drama"])
    }

    @Test func splitsMixedDelimitersAndTrims() {
        #expect(ProgramCategories.chips(from: "Drama, Crime / Thriller | ") ==
                ["Drama", "Crime", "Thriller"])
    }

    @Test func deduplicatesCaseInsensitively() {
        #expect(ProgramCategories.chips(from: "News, news, NEWS") == ["News"])
    }
}
