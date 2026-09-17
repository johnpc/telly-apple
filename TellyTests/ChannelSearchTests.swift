import Testing
@testable import Telly

/// The pure channel search filter: trimming, empty/whitespace passthrough,
/// case- and diacritic-insensitive name matching, all-digit number-prefix
/// matching, order preservation, and matching across groups.
struct ChannelSearchTests {
    private func ch(_ name: String, number: Int, group: String? = "Live") -> ChannelEntity {
        ChannelEntity(id: number, playlistId: 1, number: number, sortIndex: number,
                      source: ChannelSource(name: name, groupTitle: group,
                                            streamUrl: "http://127.0.0.1/\(number).ts"))
    }

    @Test func emptyQueryReturnsAll() {
        let all = [ch("News", number: 1), ch("Movie", number: 2)]
        #expect(ChannelSearch.filter(all, query: "").map(\.number) == [1, 2])
    }

    @Test func whitespaceOnlyReturnsAll() {
        let all = [ch("News", number: 1), ch("Movie", number: 2)]
        #expect(ChannelSearch.filter(all, query: "   ").map(\.number) == [1, 2])
    }

    @Test func leadingTrailingTrimmed() {
        #expect(ChannelSearch.matches("  Movie  ", ch("Movie Time", number: 5)))
    }

    @Test func caseInsensitive() {
        #expect(ChannelSearch.matches("movie", ch("Movie Time", number: 5)))
    }

    @Test func diacriticInsensitive() {
        #expect(ChannelSearch.matches("cafe", ch("Café Central", number: 7)))
    }

    @Test func substringMid() {
        #expect(ChannelSearch.matches("time", ch("Movie Time", number: 5)))
    }

    @Test func noMatchEmpty() {
        let all = [ch("News", number: 1), ch("Movie", number: 2)]
        #expect(ChannelSearch.filter(all, query: "zzz").isEmpty)
    }

    @Test func numberExact() {
        #expect(ChannelSearch.matches("12", ch("News", number: 12)))
    }

    @Test func numberPrefix() {
        let all = [ch("A", number: 1), ch("B", number: 10), ch("C", number: 12), ch("D", number: 20)]
        #expect(ChannelSearch.filter(all, query: "1").map(\.number) == [1, 10, 12])
    }

    @Test func nonNumericIgnoresNumbers() {
        // "20" is a number; a non-numeric query must not match it via the number path.
        #expect(!ChannelSearch.matches("abc", ch("News", number: 20)))
    }

    @Test func numericMatchesNameWithDigits() {
        #expect(ChannelSearch.matches("4", ch("Channel 4", number: 99)))
    }

    @Test func filterPreservesOrder() {
        let all = [ch("Movie One", number: 3), ch("Skip", number: 4), ch("Movie Two", number: 1)]
        #expect(ChannelSearch.filter(all, query: "movie").map(\.number) == [3, 1])
    }

    @Test func matchesAcrossGroups() {
        let all = [ch("Sport HD", number: 1, group: "Sports"),
                   ch("Sport 4K", number: 2, group: "UHD")]
        #expect(ChannelSearch.filter(all, query: "sport").map(\.number) == [1, 2])
    }
}
