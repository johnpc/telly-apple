import SwiftUI

/// The concrete catch-up / live-tune playback triggers behind ``GuideGridScreen``'s
/// `play` switch. Kept in a sibling file so `+Activate` stays lean; the wiring is
/// unchanged from the pre-panel flow — only the call site moved (a panel button or
/// a filler tap) — so the shared live engine / catch-up path is untouched.
extension GuideGridScreen {
    func playCatchup(_ channel: ChannelEntity, _ cell: GuideCell) {
        guard let attributes = channel.catchupAttributes(),
              let url = CatchupUrlBuilder.build(
                  streamUrl: channel.source.streamUrl, attributes: attributes,
                  startMs: cell.startMs, endMs: cell.endMs, nowMs: model.now()) else { return }
        target = .catchup(CatchupRequest(channel: channel, url: url,
                                         title: cell.program?.details.title,
                                         startMs: cell.startMs, endMs: cell.endMs))
    }

    func tune(_ channel: ChannelEntity) {
        if let onLiveTune { onLiveTune(channel) } else {
            target = .live(channelId: channel.id, url: channel.source.streamUrl)
        }
    }
}
