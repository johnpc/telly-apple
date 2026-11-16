import SwiftUI

/// The guide's fullscreen-cover fork, extracted from ``GuideGridScreen`` so the
/// at-cap screen file stays lean: a `.catchup` target opens the transport-driven
/// ``CatchupPlaybackScreen``; a `.live` target plays through the chrome-less
/// ``PlaybackScreen``. The switch is exhaustive over ``GuidePlaybackTarget``.
extension GuideGridScreen {
    @ViewBuilder func playbackCover(_ target: GuidePlaybackTarget) -> some View {
        switch target {
        case let .catchup(request):
            CatchupPlaybackScreen(model: makeCatchupModel(request), request: request)
        case let .live(_, url):
            PlaybackScreen(streamUrl: url, engine: makeEngine(),
                           is24h: model.is24h, timeZone: model.timeZone)
        }
    }
}
