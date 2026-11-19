import SwiftUI

/// Forwards tvOS remote input (D-pad moves, OK tap, MENU/BACK) into the live
/// model's `onKey`. Carried by ``PlaybackKeyLayer`` (below) rather than applied
/// to the stage's ZStack — see that type for why. A transparent pass-through off
/// tvOS, where taps/swipes are mapped by the screen.
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

/// The live stage's ONE focusable node: a transparent full-screen layer carrying
/// ``PlaybackKeyForwarder``, composed as a SIBLING of the overlay layers inside
/// ``LivePlaybackScreen``'s ZStack — never their ancestor. When the forwarder sat
/// on the ZStack itself, every overlay (info / zap / panel / pickers) was a
/// descendant of the key-handling node and inherited its key-press-handler
/// environment; on tvOS 27.2 SwiftUI then crashed (EXC_BAD_ACCESS deep in
/// StackLayout / PropertyList.Tracker, no app frames) the second time the
/// auto-hidden info overlay was raised, walking layout state freed with the
/// previous overlay. Overlays outside the handler's subtree carry no such
/// dependency, and the layer still receives every remote press because it is the
/// only focusable view on the stage. `ignoresSafeArea` keeps it full-screen.
struct PlaybackKeyLayer: View {
    let model: LivePlaybackModel

    var body: some View {
        Color.clear.ignoresSafeArea().modifier(PlaybackKeyForwarder(model: model))
    }
}
