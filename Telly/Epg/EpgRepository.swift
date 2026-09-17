import Foundation

/// Guide reads with per-channel EPG offsets applied. Holds no wall clock: the
/// caller supplies `atMs`/window bounds and a `[tvgId: offsetMs]` map. Stored
/// times are real, so a query is widened by the offsets to catch rows that
/// shift into view, then results are shifted back into caller (display) time.
struct EpgRepository {
    let store: ProgramStore

    /// Programmes to display in `[fromMs, toMs)` with offsets applied. The store
    /// query is padded via `EpgOffsets.queryFrom/queryTo`, then the padded
    /// superset is shifted and trimmed back to the requested window.
    func programs(tvgIds: [String], fromMs: Int, toMs: Int,
                  offsets: [String: Int]) throws -> [ProgramEntity] {
        let rows = try store.window(
            tvgIds: tvgIds,
            fromMs: EpgOffsets.queryFrom(fromMs, offsets: offsets),
            toMs: EpgOffsets.queryTo(toMs, offsets: offsets))
        return EpgOffsets.windowed(rows, offsets: offsets, fromMs: fromMs, toMs: toMs)
    }

    /// Per-channel now/next at `atMs` with offsets applied. Channels with no
    /// data are absent from the result (see `NowNextResolver.resolve`).
    func nowNext(tvgIds: [String], atMs: Int,
                 offsets: [String: Int]) throws -> [String: NowNext] {
        let rows = try store.airingOrUpcoming(
            tvgIds: tvgIds, atMs: EpgOffsets.queryFrom(atMs, offsets: offsets))
        return NowNextResolver.resolve(EpgOffsets.shifted(rows, offsets: offsets), atMs: atMs)
    }
}
