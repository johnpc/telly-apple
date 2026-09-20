import Foundation

/// What a remote key does inside a vertical multiview list (the pane menu or the
/// channel picker): step the highlight, activate the highlighted row, or close
/// back one level. Every other key is inert. Pure and shared by both lists so the
/// D-pad vocabulary stays identical — unit-tested without a view.
enum MultiviewListAction: Equatable, Sendable {
    case move(Int)
    case activate
    case close
    case ignored
}

/// The pure key→action map for a multiview vertical list. UP/DOWN move the
/// highlight, OK activates it, MENU/BACK close the list; LEFT/RIGHT and media
/// keys are inert here (the grid owns 2-D moves, the list is 1-D).
enum MultiviewMenuPolicy {
    static func action(for key: PlaybackKey) -> MultiviewListAction {
        switch key {
        case .up: return .move(-1)
        case .down: return .move(1)
        case .ok: return .activate
        case .back, .menu: return .close
        default: return .ignored
        }
    }

    /// A selection index moved by `delta` and clamped into `0..<count` (or 0 when
    /// the list is empty). Shared by both lists so clamping can't drift.
    static func moved(selection: Int, by delta: Int, count: Int) -> Int {
        guard count > 0 else { return 0 }
        return min(max(selection + delta, 0), count - 1)
    }
}
