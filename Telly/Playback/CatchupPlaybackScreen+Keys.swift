import SwiftUI

/// Platform input for ``CatchupPlaybackScreen``, split out to keep the screen
/// lean — the ``PlaybackKeyForwarder`` precedent, but targeting the catch-up
/// model's `onKey` (it is typed to ``LivePlaybackModel`` and cannot be reused).
/// tvOS forwards D-pad moves through ``CatchupKeyPolicy`` and exits on MENU/BACK;
/// iPhone/iPad map a horizontal swipe to a discrete skip-step seek.
private struct CatchupKeys: ViewModifier {
    let model: CatchupPlaybackModel

    func body(content: Content) -> some View {
        #if os(tvOS)
        content.focusable()
            .onMoveCommand { seek($0) }
            .onExitCommand { model.back() }
            .onPlayPauseCommand { model.togglePause() }
        #else
        content.gesture(DragGesture(minimumDistance: 20).onEnded { value in
            guard abs(value.translation.width) > abs(value.translation.height) else { return }
            _ = model.onKey(value.translation.width < 0 ? .left : .right, overlay: .none)
        })
        #endif
    }

    #if os(tvOS)
    private func seek(_ direction: MoveCommandDirection) {
        switch direction {
        case .left: _ = model.onKey(.left, overlay: .none)
        case .right: _ = model.onKey(.right, overlay: .none)
        case .up: _ = model.onKey(.up, overlay: .none)
        case .down: _ = model.onKey(.down, overlay: .none)
        @unknown default: break
        }
    }
    #endif
}

extension View {
    /// Attach the catch-up transport input for `model`.
    func catchupKeys(_ model: CatchupPlaybackModel) -> some View {
        modifier(CatchupKeys(model: model))
    }
}
