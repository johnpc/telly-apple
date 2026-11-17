import SwiftUI

/// The guide's time header and the header+grid body, split out of the screen to
/// keep it within budget. On tvOS the body is ONE focus target driving the cell
/// cursor (`+Input`), so the chips and day chrome above it stay ordinary
/// focusable buttons the remote can reach.
extension GuideGridScreen {
    var gridBody: some View {
        let body = VStack(spacing: 0) { header; grid }
        #if os(tvOS)
        return tvGridFocus(body)
        #else
        return body
        #endif
    }

    private var header: some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: columnWidth, height: GuideGeometry.rowHeight)
            GuideTimeHeaderView(ticks: model.timelineTicks)
                .frame(width: model.viewport, height: GuideGeometry.rowHeight, alignment: .leading)
                .clipped()
        }
    }
}
