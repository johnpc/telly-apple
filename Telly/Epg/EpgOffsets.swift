import Foundation

/// Per-channel "EPG time offset" math: a channel's programme times are shifted
/// by its offset for every lookup, so the grid, overlays and now/next all move
/// together. Stored rows keep their real times, so a window query must reach
/// `offset` further out to catch rows that shift INTO the window; the padded
/// superset is shifted and trimmed here.
enum EpgOffsets {
    private static let minuteMs = 60_000

    /// tvgId -> offset millis; first channel wins a shared tvg-id.
    static func ofMinutes(_ offsets: [TvgOffset]) -> [String: Int] {
        var out: [String: Int] = [:]
        for row in offsets {
            guard let tvgId = row.tvgId, out[tvgId] == nil else { continue }
            out[tvgId] = row.epgOffsetMinutes * minuteMs
        }
        return out
    }

    /// Query lower bound catching rows that shift forward into the window.
    static func queryFrom(_ fromMs: Int, offsets: [String: Int]) -> Int {
        fromMs - max(offsets.values.max() ?? 0, 0)
    }

    /// Query upper bound catching rows that shift backward into the window.
    static func queryTo(_ toMs: Int, offsets: [String: Int]) -> Int {
        toMs - min(offsets.values.min() ?? 0, 0)
    }

    /// Each programme moved by its channel's offset (0 when none).
    static func shifted(_ programs: [ProgramEntity], offsets: [String: Int]) -> [ProgramEntity] {
        guard !offsets.isEmpty else { return programs }
        return programs.map { program in
            let offset = offsets[program.channelTvgId] ?? 0
            guard offset != 0 else { return program }
            return ProgramEntity(id: program.id, channelTvgId: program.channelTvgId,
                                 startMs: program.startMs + offset, endMs: program.endMs + offset,
                                 details: program.details)
        }
    }

    /// Shift, then trim back to the requested [fromMs, toMs) display window.
    static func windowed(_ programs: [ProgramEntity], offsets: [String: Int],
                         fromMs: Int, toMs: Int) -> [ProgramEntity] {
        shifted(programs, offsets: offsets).filter { $0.endMs > fromMs && $0.startMs < toMs }
    }
}
