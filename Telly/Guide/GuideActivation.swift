import Foundation

/// The pure cell-activation decision, ported 1:1 from Android `GuideActivation`
/// (GuideActivation.kt:36-49): catch-up WINS FIRST — OK on a real PAST programme
/// of a catch-up-capable channel within its `catchup-days` horizon plays the
/// archive; otherwise the airing cell tunes live, an info-carrying cell shows
/// detail, and a "No information" filler is inert. (Apple folds Android's
/// two-stage preview→fullscreen tune into the single-stage `.tune`.)
enum GuideActivation {
    /// Playability-first: airing/future cells report `playable == false`, so an
    /// airing cell falls through to `.tune` even though its channel could serve
    /// catch-up — matching Android's airing branch.
    static func activate(row: GuideRow, cell: GuideCell, nowMs: Int) -> GuideSelection {
        if CatchupPlayability.playable(channel: row.channel, startMs: cell.startMs,
                                       endMs: cell.endMs, hasInfo: cell.hasInfo, nowMs: nowMs) {
            return .catchup(row.channel, cell)
        }
        if cell.contains(nowMs) { return .tune(row.channel) }
        if cell.hasInfo { return .info(cell) }
        return .none
    }
}
