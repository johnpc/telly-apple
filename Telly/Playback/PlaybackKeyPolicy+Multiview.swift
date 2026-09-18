import Foundation

/// The multiview branch of ``PlaybackKeyPolicy``, split into a sibling extension
/// so the base policy stays within the source-line budget. In the N-up grid the
/// D-pad moves the active tile, OK promotes it to fullscreen, and MENU/BACK exit
/// back to single-stream playback; every other key is unbound here.
extension PlaybackKeyPolicy {
    static func withinMultiview(_ key: PlaybackKey) -> PlaybackCommand? {
        switch key {
        case .up: return .moveMultiviewActive(.up)
        case .down: return .moveMultiviewActive(.down)
        case .left: return .moveMultiviewActive(.left)
        case .right: return .moveMultiviewActive(.right)
        case .ok: return .promoteMultiviewActive
        case .back, .menu: return .exitMultiview
        default: return nil
        }
    }
}
