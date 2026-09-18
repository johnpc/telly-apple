import SwiftUI

/// Guide-screen chrome for `GuideGridScreen`: a platform-appropriate backdrop
/// (dark on tvOS, where that reads as native; the system background on iPhone/
/// iPad so the grid honours the app's light/system scheme like every other
/// screen) plus a per-minute tick that advances the now-line without a wasteful
/// per-second timer. Both stay off `GuideGridScreen` to keep it within budget.
extension View {
    /// The guide's backdrop for the current platform (tvOS stays a dark surface;
    /// elsewhere the system background follows the app's light/dark appearance).
    func guideSurface() -> some View {
        #if os(tvOS)
        background(Color(white: 0.09).ignoresSafeArea())
            .environment(\.colorScheme, .dark)
        #else
        background(Color(.systemBackground).ignoresSafeArea())
        #endif
    }

    /// Advances the now-line once a minute while the guide is on screen; the
    /// timer subscription is created once and cancels when the view goes away.
    func guideMinuteTick(_ action: @escaping () -> Void) -> some View {
        modifier(GuideMinuteTick(action: action))
    }
}

/// Drives a once-a-minute callback from a coalesced main-run-loop timer held for
/// the view's lifetime, so the subscription starts once and cancels on teardown
/// (no retain past the guide, no fire when the view isn't in the hierarchy).
private struct GuideMinuteTick: ViewModifier {
    let action: () -> Void
    @State private var ticker = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    func body(content: Content) -> some View {
        content.onReceive(ticker) { _ in action() }
    }
}
