import SwiftUI
#if os(iOS)
import UIKit
#endif

/// The iPhone / iPad tap feel: the control dips to `Motion.pressScale` and dims
/// slightly while held, springing back on release (instant under Reduce Motion).
/// tvOS keeps its native focus behaviour, so there the style is a passthrough.
struct TellyPressButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(scale(configuration.isPressed))
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(Motion.gated(Motion.focus, reduceMotion: reduceMotion),
                       value: configuration.isPressed)
    }

    private func scale(_ pressed: Bool) -> CGFloat {
        #if os(tvOS)
        return 1
        #else
        return pressed ? Motion.pressScale : 1
        #endif
    }
}

/// A light selection haptic, iOS / iPadOS only — tvOS has no haptic engine, so
/// the call compiles to nothing there. Used on discrete selections (tuning a
/// channel, switching a group) where a gentle tap confirms the action.
enum TellyHaptics {
    static func selection() {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
}
