import Foundation

/// Assembles the guide grid's rows: groups the window's programmes by tvg-id,
/// then for each channel (in the supplied order) builds a contiguous cell strip
/// from the programmes matching its `epgId`. Channels with a nil `epgId` — or an
/// `epgId` no programme carries — become an all-filler row. `displayNumber` is
/// the channel's playlist number (per-group renumber is deferred). View-free so
/// the whole assembly is unit-testable headlessly.
enum GuideRowsBuilder {
    /// One `GuideRow` per channel, ordered as `channels`, cells covering `span`.
    static func build(channels: [ChannelEntity], programs: [ProgramEntity],
                      span: GuideSpan) -> [GuideRow] {
        let byChannel = Dictionary(grouping: programs, by: { $0.channelTvgId })
        return channels.map { channel in
            let matched = channel.epgId.flatMap { byChannel[$0] } ?? []
            return GuideRow(channel: channel, displayNumber: channel.number,
                            cells: GuideCellsBuilder.build(programs: matched, span: span))
        }
    }
}
