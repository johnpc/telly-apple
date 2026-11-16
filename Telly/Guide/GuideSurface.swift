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
}
