import Foundation

/// Pure assembly of the search shelves from query rows (Android
/// `SearchResultsBuilder`): channel cards keep the query's name order and carry
/// their airing programme; the Programs section groups programme matches into
/// one master entry per channel (case-insensitive name order, ties by number)
/// whose airings stay chronological, one per airing, never deduped or merged.
enum SearchResultsBuilder {
    static func channels(matches: [ChannelEntity], nowNext: [String: NowNext],
                         atMs: Int, timeZone: TimeZone) -> [SearchChannelHit] {
        matches.map { channel in
            let now = channel.epgId.flatMap { nowNext[$0] }?.now
            return SearchChannelHit(
                channel: channel,
                nowTitle: now?.details.title,
                progress: now.flatMap {
                    ProgramProgress.fraction(nowMs: atMs, startMs: $0.startMs, endMs: $0.endMs)
                })
        }
    }

    static func programs(matches: [ProgramEntity], channels: [ChannelEntity],
                         atMs: Int, timeZone: TimeZone) -> [SearchProgramChannel] {
        let byTvgId = channelByTvgId(channels)
        return Dictionary(grouping: matches, by: { $0.channelTvgId })
            .compactMap { tvgId, airings in
                byTvgId[tvgId].map { group($0, airings: airings, atMs: atMs, timeZone: timeZone) }
            }
            .sorted(by: ordered)
    }

    private static func ordered(_ a: SearchProgramChannel, _ b: SearchProgramChannel) -> Bool {
        let byName = a.channel.displayName.localizedCaseInsensitiveCompare(b.channel.displayName)
        if byName != .orderedSame { return byName == .orderedAscending }
        return a.channel.number < b.channel.number
    }

    private static func group(_ channel: ChannelEntity, airings: [ProgramEntity],
                              atMs: Int, timeZone: TimeZone) -> SearchProgramChannel {
        SearchProgramChannel(
            channel: channel,
            airings: airings.sorted { $0.startMs < $1.startMs }
                .map { hit($0, channel: channel, atMs: atMs, timeZone: timeZone) })
    }

    private static func hit(_ program: ProgramEntity, channel: ChannelEntity,
                            atMs: Int, timeZone: TimeZone) -> SearchProgramHit {
        let airing = program.startMs <= atMs && atMs < program.endMs
        return SearchProgramHit(
            program: program, channel: channel,
            title: program.details.title,
            timeText: SearchAirTime.text(program: program, atMs: atMs, timeZone: timeZone),
            progress: airing
                ? ProgramProgress.fraction(nowMs: atMs, startMs: program.startMs, endMs: program.endMs)
                : nil,
            remaining: airing ? "\(remainingMinutes(endMs: program.endMs, atMs: atMs)) min" : nil)
    }

    /// Minutes left in the programme, rounded UP (Android `ProgramTimes.remainingMinutes`).
    private static func remainingMinutes(endMs: Int, atMs: Int) -> Int {
        (max(endMs - atMs, 0) + 60_000 - 1) / 60_000
    }

    /// First visible channel wins when several share an EPG id (remap-aware).
    private static func channelByTvgId(_ channels: [ChannelEntity]) -> [String: ChannelEntity] {
        var map: [String: ChannelEntity] = [:]
        for channel in channels {
            if let id = channel.epgId, map[id] == nil { map[id] = channel }
        }
        return map
    }
}
