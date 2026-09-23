import VLCKitSPM

extension VLCKitPlayerEngine {
    /// Thin, untestable translation of VLCKit's ObjC state enum into our own
    /// ``VlcPlaybackState`` mirror — the only place that touches VLCKit types.
    /// All decision logic lives in the pure ``PlaybackReducer/onVlcState(_:)``.
    static func mapped(_ state: VLCMediaPlayerState) -> VlcPlaybackState {
        switch state {
        case .opening: return .opening
        case .buffering: return .buffering
        case .esAdded: return .esAdded
        case .playing: return .playing
        case .paused: return .paused
        case .stopped: return .stopped
        case .ended: return .ended
        case .error: return .error
        @unknown default: return .buffering
        }
    }
}
