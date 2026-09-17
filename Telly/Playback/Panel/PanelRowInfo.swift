import Foundation

/// One channel-panel row's rendered fields: the display number, name/logo, and
/// the now/next programme titles, the current air-time range, and elapsed
/// progress. Pure so the row layout is unit-tested without a view. Ported from
/// the Android `PanelRow`.
struct PanelRowInfo: Equatable {
    let displayNumber: Int
    let name: String
    let logoUrl: String?
    let nowTitle: String?
    let nowRange: String?
    let nextTitle: String?
    let progress: Double?
}

/// Builds the ordered panel rows for a group, reusing the info overlay's pure
/// now/next text + progress helpers rather than re-inlining any formatting.
/// `displayNumber` is the channel number under "All channels", else the 1-based
/// row position (Android `PanelRows`).
enum PanelRowBuilder {
    static func rows(_ channels: [ChannelEntity], group: String,
                     nowNext: (ChannelEntity) -> NowNext?,
                     nowMs: Int, timeZone: TimeZone = .current) -> [PanelRowInfo] {
        let useNumber = group == ChannelPanelGroups.allChannels
        return channels.enumerated().map { index, channel in
            row(channel, number: useNumber ? channel.number : index + 1,
                info: nowNext(channel), nowMs: nowMs, timeZone: timeZone)
        }
    }

    private static func row(_ channel: ChannelEntity, number: Int, info: NowNext?,
                            nowMs: Int, timeZone: TimeZone) -> PanelRowInfo {
        PanelRowInfo(
            displayNumber: number,
            name: channel.displayName,
            logoUrl: channel.source.logoUrl,
            nowTitle: InfoOverlayText.nowTitle(info),
            nowRange: range(info?.now, timeZone: timeZone),
            nextTitle: InfoOverlayText.nextTitle(info),
            progress: info?.now.flatMap {
                ProgramProgress.fraction(nowMs: nowMs, startMs: $0.startMs, endMs: $0.endMs)
            })
    }

    private static func range(_ program: ProgramEntity?, timeZone: TimeZone) -> String? {
        guard let program else { return nil }
        let start = InfoOverlayText.timeLabel(program.startMs, timeZone: timeZone)
        return "\(start) – \(InfoOverlayText.timeLabel(program.endMs, timeZone: timeZone))"
    }
}
