#if os(tvOS)
import SwiftUI

/// tvOS D-pad + select handling for the guide grid, split out of the screen so
/// it stays within the source-line budget. Each move delegates to the model's
/// focus navigation; select activates the currently focused cell.
extension GuideGridScreen {
    func move(_ direction: MoveCommandDirection) {
        switch direction {
        case .left: model.focusLeft()
        case .right: model.focusRight()
        case .up: model.focusUp()
        case .down: model.focusDown()
        @unknown default: break
        }
    }

    func activateFocused() {
        guard let focus = model.focus, model.rows.indices.contains(focus.rowIndex) else { return }
        activate(focus.cell, row: model.rows[focus.rowIndex])
    }
}
#endif
