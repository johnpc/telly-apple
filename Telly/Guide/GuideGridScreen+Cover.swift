import SwiftUI

/// The guide's fullscreen-cover fork, extracted from ``GuideGridScreen`` so the
/// at-cap screen file stays lean: a catch-up target (`request != nil`) opens the
/// transport-driven ``CatchupPlaybackScreen``; every other target keeps playing
/// through the chrome-less ``PlaybackScreen`` unchanged.
extension GuideGridScreen {
    @ViewBuilder func playbackCover(_ target: GuidePlaybackTarget) -> some View {
        if let request = target.request {
            CatchupPlaybackScreen(model: makeCatchupModel(request), request: request)
        } else {
            PlaybackScreen(streamUrl: target.url, engine: makeEngine(),
                           catchup: target.catchup, is24h: model.is24h, timeZone: model.timeZone)
        }
    }
}
