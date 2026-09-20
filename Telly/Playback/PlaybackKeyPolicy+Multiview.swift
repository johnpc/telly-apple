import Foundation

/// The multiview branch of ``PlaybackKeyPolicy``, split into a sibling extension
/// so the base policy stays within the source-line budget. In the N-up grid the
/// D-pad moves the active tile, OK opens the per-pane menu (Android's OK-on-pane —
/// Fullscreen is a menu row, not the direct OK action), and MENU/BACK exit back to
/// single-stream playback; every other key is unbound here. Once a pane menu or
/// picker is up, the model routes keys through ``MultiviewMenuPolicy`` instead.
extension PlaybackKeyPolicy {
    static func withinMultiview(_ key: PlaybackKey) -> PlaybackCommand? {
        switch key {
        case .up: return .moveMultiviewActive(.up)
        case .down: return .moveMultiviewActive(.down)
        case .left: return .moveMultiviewActive(.left)
        case .right: return .moveMultiviewActive(.right)
        case .ok: return .openMultiviewPaneMenu
        case .back, .menu: return .exitMultiview
        default: return nil
        }
    }
}
