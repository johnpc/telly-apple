import SwiftUI

/// Search's result cover, split out so ``SearchScreen`` stays within the line
/// budget. When a ``LiveStagePresentation`` is wired (the toolbar path) it opens
/// the SHARED live stage — the SAME persistent engine, seamless with the guide
/// overlay + mini-player. When nil (the DEBUG search-within-live surface, which
/// has no shared store) it falls back to a TERMINAL per-screen ``PlaybackScreen``
/// so nothing keeps decoding after dismissal.
struct SearchTuneCover: ViewModifier {
    @Binding var target: LiveStageTarget?
    let liveStage: LiveStagePresentation?
    let makeEngine: @MainActor () -> VLCKitPlayerEngine

    func body(content: Content) -> some View {
        if let liveStage {
            content.liveStageCover($target, using: liveStage)
        } else {
            content.fullScreenCover(item: $target) { target in
                PlaybackScreen(streamUrl: target.url, engine: makeEngine())
            }
        }
    }
}
