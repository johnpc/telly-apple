/// Maps a recognised ``TouchGesture`` onto the existing ``PlaybackKey``
/// vocabulary so touch input flows through the identical
/// ``LivePlaybackModel/onKey(_:)`` → ``PlaybackKeyPolicy`` path as the tvOS
/// remote — no parallel command system. A tap opens info at bare playback and
/// dismisses any overlay otherwise (never exits to the guide, since `.back` is
/// only emitted when an overlay is up). Vertical swipes zap channels; horizontal
/// swipes are reserved (inert in the current keymap).
enum TouchKeyMap {
    static func key(for gesture: TouchGesture, overlay: PlaybackOverlay) -> PlaybackKey {
        switch gesture {
        case .tap: return overlay == .none ? .ok : .back
        case .swipeUp: return .channelUp
        case .swipeDown: return .channelDown
        case .swipeLeft: return .left
        case .swipeRight: return .right
        }
    }
}
