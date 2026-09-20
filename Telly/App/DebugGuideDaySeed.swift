#if DEBUG
import Foundation

/// DEBUG-only day-navigation screenshot support: `-tellyGuideDay N` pages the
/// seeded guide N days from now and seeds a full day of back-to-back cells at
/// that offset so a plain `simctl` screenshot captures a paged day full of real
/// titled programmes (never the real provider EPG). Split from `DebugGuideSeed`
/// to keep each file within the source-line budget.
extension DebugLaunch {
    /// The requested guide day-offset (`-tellyGuideDay 1` → next day), or nil.
    static func forcedGuideDayOffset(in args: [String]) -> Int? {
        value(for: "-tellyGuideDay", in: args).flatMap { Int($0) }
    }

    /// A full day of 30-min cells at the requested offset on the two demo
    /// channels, or [] unless `-tellyGuideDay` is set. Anchored one column before
    /// the paged window's left edge so the screenshot pane is full of cells.
    static func dayPageStrips(nowMs: Int, args: [String]) -> [XmltvProgram] {
        guard let offset = forcedGuideDayOffset(in: args) else { return [] }
        let start = GuideGeometry.halfHourFloor(nowMs, timeZone: .current)
            + offset * GuideGeometry.dayMs - GuideGeometry.halfHourMs
        return dayCells(channelId: demoEpgId, from: start)
            + dayCells(channelId: moviesEpgId, from: start)
    }

    private static func dayCells(channelId: String, from start: Int) -> [XmltvProgram] {
        let half = GuideGeometry.halfHourMs
        return (0..<50).map { index in
            XmltvProgram(channelId: channelId, startMs: start + index * half,
                         endMs: start + (index + 1) * half,
                         details: ProgramDetails(title: "Program \(index + 1)"))
        }
    }
}
#endif
