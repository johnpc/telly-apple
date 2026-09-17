import Foundation

/// Runs one search over the stores: channels by name substring or number
/// prefix (visible-set order, via ``ChannelSearch``), programmes by title
/// word-prefix still airing or upcoming (capped at ``programLimit``). Escaping,
/// filtering and formatting live in the pure ``SearchQuery``/
/// ``SearchResultsBuilder``; this type only orchestrates — the Apple mirror of
/// the Android `SearchRepository`.
struct SearchRepository {
    let channelStore: ChannelStore
    let programStore: ProgramStore
    let epg: EpgRepository

    func search(_ raw: String, atMs: Int, timeZone: TimeZone) throws -> SearchResults {
        let q = SearchQuery.normalize(raw)
        guard !q.isEmpty else { return SearchResults() }
        let visible = try channelStore.visibleChannels()
        let matches = ChannelSearch.filter(visible, query: q)
        let nowNext = try nowNext(for: matches, over: visible, atMs: atMs)
        let programs = try programStore.searchTitles(
            titleLike: SearchQuery.nameLike(q), atMs: atMs, limit: Self.programLimit)
        return SearchResults(
            query: q,
            channels: SearchResultsBuilder.channels(
                matches: matches, nowNext: nowNext, atMs: atMs, timeZone: timeZone),
            programs: SearchResultsBuilder.programs(
                matches: programs, channels: visible, atMs: atMs, timeZone: timeZone))
    }

    /// Now/next for the name-matched channels, with offsets computed over the
    /// FULL visible set (matching Android) so a shared tvg-id resolves the same.
    private func nowNext(for matches: [ChannelEntity], over visible: [ChannelEntity],
                         atMs: Int) throws -> [String: NowNext] {
        try epg.nowNext(tvgIds: matches.compactMap(\.epgId),
                        atMs: atMs, offsets: EpgOffsets.map(for: visible))
    }

    /// Result cap for the programme list (Android `PROGRAM_LIMIT`) — deferred
    /// here from the search DAO slice; bounds the leading-wildcard scan.
    static let programLimit = 100
}
