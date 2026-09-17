import SwiftUI

/// Forwards tvOS remote input (D-pad moves, OK tap, MENU/BACK) into the live
/// model's `onKey`, extracted from `LivePlaybackScreen` so the screen stays
/// within the source-line budget once the multiview overlay branch is added. A
/// transparent pass-through off tvOS, where taps/swipes are mapped by the screen.
struct PlaybackKeyForwarder: ViewModifier {
    let model: LivePlaybackModel

    func body(content: Content) -> some View {
        #if os(tvOS)
        content
            .focusable()
            .onMoveCommand { direction in
                switch direction {
                case .up: _ = model.onKey(.up)
                case .down: _ = model.onKey(.down)
                case .left: _ = model.onKey(.left)
                case .right: _ = model.onKey(.right)
                @unknown default: break
                }
            }
            .onTapGesture { _ = model.onKey(.ok) }
            .onExitCommand { _ = model.onKey(.back) }
        #else
        content
        #endif
    }
}

extension View {
    /// Attach the tvOS remote-key forwarder for `model`.
    func playbackKeyForwarder(_ model: LivePlaybackModel) -> some View {
        modifier(PlaybackKeyForwarder(model: model))
    }
}
