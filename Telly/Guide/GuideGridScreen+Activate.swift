import SwiftUI

/// The guide's selection→panel/playback bridge, extracted from ``GuideGridScreen``
/// so the at-cap screen file stays lean. OK/tap on an info-carrying cell opens the
/// program info panel (``GuideGridModel/infoTarget(for:row:)``), where the synopsis
/// sits above the per-cell action (Watch / catch-up / My List). A "No information"
/// filler carries no panel, so it tunes straight through (`play`) as before; the
/// panel's Watch/catch-up buttons route back through the same `play`.
extension GuideGridScreen {
    func activate(_ cell: GuideCell, row: GuideRow) {
        if let target = model.infoTarget(for: cell, row: row) {
            infoTarget = target
        } else {
            play(model.selectCell(cell, row: row))
        }
    }

    /// Runs a resolved selection: catch-up resolves an archive URL (mirroring
    /// Android `TuneController.tune(catchupUrl:)`), an airing cell tunes live, and
    /// info / filler outcomes are inert (the panel, not playback, handles info).
    func play(_ selection: GuideSelection) {
        switch selection {
        case let .catchup(channel, cell): playCatchup(channel, cell)
        case let .tune(channel): tune(channel)
        case .info, .none: break
        }
    }
}

/// Identifies the stream being played from the grid (drives the fullscreen
/// cover); `catchup` is non-nil only for an archive playback.
struct GuidePlaybackTarget: Identifiable {
    let id: Int
    let url: String
    let catchup: CatchupBadge?
    /// The resolved archive request; non-nil only for a catch-up target, which
    /// routes to ``CatchupPlaybackScreen`` (nil plays through ``PlaybackScreen``).
    let request: CatchupRequest?
}
