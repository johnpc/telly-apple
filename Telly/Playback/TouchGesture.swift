import CoreGraphics

/// A touch gesture recognised on the iPhone/iPad live-playback stage, classified
/// from a raw drag translation before being mapped onto the existing
/// ``PlaybackKey`` vocabulary by ``TouchKeyMap``. This is the thin touch mirror
/// of the tvOS remote: taps and the four cardinal swipes, nothing more (S7).
enum TouchGesture: Sendable {
    case tap
    case swipeUp
    case swipeDown
    case swipeLeft
    case swipeRight

    /// Below this magnitude on both axes a drag is treated as a tap, so a single
    /// `DragGesture(minimumDistance: 0)` can classify taps and swipes alike
    /// without a competing `onTapGesture` recogniser.
    private static let minSwipe: CGFloat = 24

    /// Classify a drag translation into a gesture. Total function: a near-zero
    /// translation is a `.tap`; otherwise the dominant axis and its sign pick a
    /// cardinal swipe. SwiftUI's `translation.height` is positive downward, so a
    /// negative `dy` is an upward swipe. Ties (`|dx| == |dy|`) favour horizontal.
    static func swipe(dx: CGFloat, dy: CGFloat) -> TouchGesture {
        if abs(dx) < minSwipe && abs(dy) < minSwipe { return .tap }
        if abs(dx) >= abs(dy) { return dx < 0 ? .swipeLeft : .swipeRight }
        return dy < 0 ? .swipeUp : .swipeDown
    }
}
