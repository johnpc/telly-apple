import SwiftUI

/// The one focus / selection treatment used across the app, replacing the two
/// ad-hoc idioms it grew (the guide's 3pt outline and the lists' filled pill).
/// Every platform gets a rounded highlight pill; tvOS additionally gets a subtle
/// lift + soft shadow so the native focus feel reads. Animated with `Motion.focus`
/// and instant under Reduce Motion. `focused` is the app's own model-driven focus
/// (the key-routing models own the native focus engine), so the same Bool that
/// already picks the active row now also drives its appearance.
struct FocusStyleModifier: ViewModifier {
    let focused: Bool
    var cornerRadius: CGFloat = 8
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .background { highlight }
            .scaleEffect(scale)
            .shadow(color: shadowColor, radius: shadowRadius, y: shadowY)
            .animation(Motion.gated(Motion.focus, reduceMotion: reduceMotion), value: focused)
    }

    @ViewBuilder private var highlight: some View {
        if focused {
            RoundedRectangle(cornerRadius: cornerRadius).fill(Color.white.opacity(0.18))
        }
    }

    /// tvOS lifts the focused element; every other platform (and Reduce Motion)
    /// keeps the flat pill only.
    private var lifted: Bool {
        #if os(tvOS)
        focused && !reduceMotion
        #else
        false
        #endif
    }

    private var scale: CGFloat { lifted ? Motion.focusScale : 1 }
    private var shadowColor: Color { .black.opacity(lifted ? 0.35 : 0) }
    private var shadowRadius: CGFloat { lifted ? 12 : 0 }
    private var shadowY: CGFloat { lifted ? 6 : 0 }
}

extension View {
    /// Apply the shared focus / selection treatment. `cornerRadius` matches the
    /// host surface (guide cells use 4, list pills 8).
    func tellyFocus(_ focused: Bool, cornerRadius: CGFloat = 8) -> some View {
        modifier(FocusStyleModifier(focused: focused, cornerRadius: cornerRadius))
    }
}
