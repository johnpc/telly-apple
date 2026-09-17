import Foundation

/// Builds one channel's contiguous cell strip for a materialised `GuideSpan`.
/// Programmes are sorted, clamped/dropped at the span edges, and every EPG gap
/// (before the first, between programmes, and after the last) is back-filled
/// with 30-min "No information" filler cells (`program == nil`) snapped to the
/// 30-min grid anchored at `span.fromMs` (already a half-hour mark). The result
/// tiles `[span.fromMs, span.toMs)` with no gaps and no overlaps. View-free, so
/// the fold is unit-testable headlessly; `GuideGeometry.halfHourMs` sets step.
enum GuideCellsBuilder {
    /// Cells covering the whole span: a `GuideCell(program:)` per in-span
    /// programme plus grid-aligned filler for every uncovered stretch.
    static func build(programs: [ProgramEntity], span: GuideSpan) -> [GuideCell] {
        var cells: [GuideCell] = []
        var cursor = span.fromMs
        for program in inSpan(programs, span: span) {
            let start = max(program.startMs, cursor)
            let end = min(program.endMs, span.toMs)
            guard end > start else { continue }
            appendFillers(from: cursor, to: start, origin: span.fromMs, into: &cells)
            cells.append(GuideCell(startMs: start, endMs: end, program: program))
            cursor = end
        }
        appendFillers(from: cursor, to: span.toMs, origin: span.fromMs, into: &cells)
        return cells
    }

    /// Programmes overlapping `[span.fromMs, span.toMs)`, sorted by start.
    private static func inSpan(_ programs: [ProgramEntity], span: GuideSpan) -> [ProgramEntity] {
        programs
            .filter { $0.endMs > span.fromMs && $0.startMs < span.toMs }
            .sorted { $0.startMs < $1.startMs }
    }

    /// Emits grid-aligned filler cells covering `[from, to)`, splitting on every
    /// 30-min grid mark so filler tiles line up with the timeline header.
    private static func appendFillers(from: Int, to: Int, origin: Int, into cells: inout [GuideCell]) {
        guard from < to else { return }
        var boundaries = [from]
        boundaries.append(contentsOf: gridMarksBetween(from, to, origin: origin))
        boundaries.append(to)
        for index in 0..<(boundaries.count - 1) {
            cells.append(GuideCell(startMs: boundaries[index], endMs: boundaries[index + 1], program: nil))
        }
    }

    /// The 30-min grid marks (anchored at `origin`) strictly inside `(from, to)`.
    private static func gridMarksBetween(_ from: Int, _ to: Int, origin: Int) -> [Int] {
        let step = GuideGeometry.halfHourMs
        var mark = origin + ((from - origin) / step + 1) * step
        var marks: [Int] = []
        while mark < to {
            marks.append(mark)
            mark += step
        }
        return marks
    }
}
