#if os(tvOS)
import SwiftUI

/// tvOS D-pad + select handling for the guide grid, split out of the screen so
/// it stays within the source-line budget. Each move delegates to the model's
/// focus navigation; select activates the currently focused cell. UP on the top
/// row hands the remote to the day chrome (`GuideFocusArea`) so the group chips,
/// day paging and "Now" stay reachable — a move-command view otherwise swallows
/// every arrow press and traps focus in the grid.
extension GuideGridScreen {
    /// The grid as the single focusable cursor surface (`focusArea == .grid`).
    func tvGridFocus<Body: View>(_ body: Body) -> some View {
        body.focusable()
            .focused($focusArea, equals: .grid)
            .accessibilityIdentifier("guide.grid")
            .onMoveCommand { move($0) }
            .onTapGesture { activateFocused() }
    }

    func move(_ direction: MoveCommandDirection) {
        switch direction {
        case .left: model.focusLeft()
        case .right: model.focusRight()
        case .up: model.focus?.rowIndex == 0 ? leaveGridUpward() : model.focusUp()
        case .down: model.focusDown()
        @unknown default: break
        }
    }

    /// Hands focus to the day chrome above the grid (Next day when it is enabled,
    /// else Previous day — a disabled button cannot take focus).
    private func leaveGridUpward() {
        focusArea = model.canPageDayForward ? .nextDay : .previousDay
    }

    func activateFocused() {
        guard let focus = model.focus, model.rows.indices.contains(focus.rowIndex) else { return }
        activate(focus.cell, row: model.rows[focus.rowIndex])
    }
}
#endif
