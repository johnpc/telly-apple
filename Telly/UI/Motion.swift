import SwiftUI

/// The app-wide motion vocabulary: one set of named animation tokens plus the
/// geometry constants the focus / overlay modifiers share, so every call site
/// animates with identical timing and no screen is ever a hard cut. Timings are
/// pinned to the Android `telly` reference: route crossfade 120ms linear;
/// overlay appear ~300ms ease-out with a subtle ~10pt rise, dismiss quick
/// (~120ms); context push 350ms / pop 140ms; focus lift ~180ms. All motion is
/// opt-out: `gated` returns `nil` (instant) under Reduce Motion, mirroring the
/// marquee's `accessibilityReduceMotion` fallback so the whole app is consistent.
enum Motion {
    // Route / screen transitions — fast linear dissolve, no slide.
    static let route = Animation.linear(duration: 0.12)
    // Context / detail push in, quicker pop back out (asymmetric on purpose).
    static let contextPush = Animation.easeOut(duration: 0.35)
    static let contextPop = Animation.easeOut(duration: 0.14)
    // Overlays: graceful appear, immediate dismiss (asymmetric, per the reference).
    static let overlayIn = Animation.easeOut(duration: 0.30)
    static let overlayOut = Animation.easeOut(duration: 0.12)
    // Focus / selection lift.
    static let focus = Animation.easeOut(duration: 0.18)

    /// Points an overlay rises as it fades in (subtle, not a full slide).
    static let overlayRise: CGFloat = 10
    /// tvOS focus lift: the focused element grows by this factor.
    static let focusScale: CGFloat = 1.08
    /// iOS/iPadOS tap press: the pressed control shrinks to this factor.
    static let pressScale: CGFloat = 0.96

    /// Reduce-Motion gate: `nil` (no animation, instant) when the user has asked
    /// for reduced motion, otherwise the supplied token. Every call site pipes
    /// its animation through here so motion is disabled system-wide as one rule.
    static func gated(_ animation: Animation, reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : animation
    }
}
