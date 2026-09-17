import SwiftUI

/// The guide's selection→playback bridge, extracted from ``GuideGridScreen`` so
/// the at-cap screen file stays lean. Maps the pure ``GuideActivation`` outcome
/// to the shared `.fullScreenCover` target: a catch-up cell resolves an archive
/// URL (mirroring Android `TuneController.tune(catchupUrl:)`) and carries a
/// ``CatchupBadge``; an airing cell tunes live; info/filler cells stay inert.
extension GuideGridScreen {
    func activate(_ cell: GuideCell, row: GuideRow) {
        switch model.selectCell(cell, row: row) {
        case let .catchup(channel, cell):
            guard let attributes = channel.catchupAttributes(),
                  let url = CatchupUrlBuilder.build(
                      streamUrl: channel.source.streamUrl, attributes: attributes,
                      startMs: cell.startMs, endMs: cell.endMs, nowMs: model.now()) else { return }
            let request = CatchupRequest(channel: channel, url: url,
                                         title: cell.program?.details.title,
                                         startMs: cell.startMs, endMs: cell.endMs)
            target = GuidePlaybackTarget(
                id: channel.id, url: url,
                catchup: CatchupBadge(title: cell.program?.details.title,
                                      startMs: cell.startMs, endMs: cell.endMs),
                request: request)
        case let .tune(channel):
            target = GuidePlaybackTarget(id: channel.id, url: channel.source.streamUrl,
                                         catchup: nil, request: nil)
        case .info, .none:
            break
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
