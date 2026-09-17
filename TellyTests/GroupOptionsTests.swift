import Testing
@testable import Telly

/// The pure group-name guards: ``GroupOptions/trimmedName(_:)`` returns nil for
/// an empty/whitespace name (the Create/Rename ignore path) and trims surrounding
/// whitespace otherwise; ``GroupOptions/isCustom(_:in:)`` is true only when a
/// custom group carries the given name (the Rename/Delete lock mirror).
struct GroupOptionsTests {
    @Test func trimmedNameIsNilWhenEmpty() {
        #expect(GroupOptions.trimmedName("") == nil)
    }

    @Test func trimmedNameIsNilWhenWhitespace() {
        #expect(GroupOptions.trimmedName("   \n\t ") == nil)
    }

    @Test func trimmedNameTrimsSurroundingWhitespace() {
        #expect(GroupOptions.trimmedName("  News  ") == "News")
    }

    @Test func isCustomTrueWhenNameMatches() {
        let customs = [CustomGroup(id: 1, name: "News"), CustomGroup(id: 2, name: "Sports")]
        #expect(GroupOptions.isCustom("Sports", in: customs))
    }

    @Test func isCustomFalseWhenNoMatchOrEmpty() {
        let customs = [CustomGroup(id: 1, name: "News")]
        #expect(GroupOptions.isCustom("Favorites", in: customs) == false)
        #expect(GroupOptions.isCustom("News", in: []) == false)
    }
}
