import Testing
@testable import Telly

/// The pure search-query core: whitespace normalization, word-prefix name
/// patterns, digits-only number-prefix patterns, and LIKE-wildcard escaping
/// (with backslash doubled first) so user input can never inject a wildcard.
struct SearchQueryTests {
    @Test func normalizeTrimsEnds() {
        #expect(SearchQuery.normalize("  news  ") == "news")
    }

    @Test func normalizeCollapsesInternalWhitespace() {
        #expect(SearchQuery.normalize("news\t  two\n\nthree") == "news two three")
    }

    @Test func normalizeEmptyStaysEmpty() {
        #expect(SearchQuery.normalize("") == "")
        #expect(SearchQuery.normalize("   \t\n ") == "")
    }

    @Test func normalizeAlreadyCleanUnchanged() {
        #expect(SearchQuery.normalize("news two") == "news two")
    }

    @Test func nameLikeAnchorsAndWraps() {
        #expect(SearchQuery.nameLike("news") == "% news%")
    }

    @Test func nameLikeEscapesPercent() {
        #expect(SearchQuery.nameLike("50%") == "% 50\\%%")
    }

    @Test func nameLikeEscapesUnderscore() {
        #expect(SearchQuery.nameLike("a_b") == "% a\\_b%")
    }

    @Test func numberLikeEmptyForNonDigit() {
        #expect(SearchQuery.numberLike("news") == "")
        #expect(SearchQuery.numberLike("2a") == "")
    }

    @Test func numberLikeEmptyForEmpty() {
        #expect(SearchQuery.numberLike("") == "")
    }

    @Test func numberLikePrefixForDigits() {
        #expect(SearchQuery.numberLike("123") == "123%")
    }

    @Test func escapeNeutralisesInjection() {
        // Literal wildcards escaped; the backslash is doubled first so the
        // escapes it introduces are not themselves re-escaped.
        #expect(SearchQuery.nameLike("100%_off") == "% 100\\%\\_off%")
    }

    @Test func escapeDoublesRawBackslash() {
        #expect(SearchQuery.nameLike("a\\b") == "% a\\\\b%")
    }
}
