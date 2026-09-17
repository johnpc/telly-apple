import SwiftUI

/// The TiviMate-style guide grid: a fixed left channel column beside a pane whose
/// 30-min header, programme strips and now-line pan in lockstep off `scrollX`
/// (all maths in the pure `Guide*` helpers). tvOS drives focus/scroll from the
/// D-pad and tunes an airing cell to fullscreen playback (DECISION 3); iPhone/iPad
/// scroll by drag, tap to activate, reduced layout when compact (DECISION 2).
struct GuideGridScreen: View {
    @State private var model: GuideGridModel
    let makeEngine: () -> VLCKitPlayerEngine
    #if !os(tvOS)
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var dragAnchor: CGFloat = 0
    #endif
    @State private var target: GuidePlaybackTarget?

    init(model: GuideGridModel, makeEngine: @escaping () -> VLCKitPlayerEngine) {
        _model = State(initialValue: model)
        self.makeEngine = makeEngine
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            grid
        }
        .task { model.load() }
        .fullScreenCover(item: $target) { PlaybackScreen(streamUrl: $0.url, engine: makeEngine()) }
        #if os(tvOS)
        .focusable()
        .onMoveCommand { move($0) }
        .onTapGesture { activateFocused() }
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

    private var grid: some View {
        ScrollView(.vertical, showsIndicators: false) {
            HStack(alignment: .top, spacing: 0) {
                GuideChannelColumnView(rows: model.rows, width: columnWidth, compact: compact)
                GuideRowsPaneView(model: model, compact: compact, onActivate: activate)
            }
        }
        #if !os(tvOS)
        .highPriorityGesture(scrollDrag)
        #endif
    }

    private func activate(_ cell: GuideCell, row: GuideRow) {
        if case .tune(let channel) = model.selectCell(cell, row: row) {
            target = GuidePlaybackTarget(id: channel.id, url: channel.source.streamUrl)
        }
    }

    private var columnWidth: CGFloat { compact ? 168 : GuideGeometry.channelColumnWidth }
    #if os(tvOS)
    private var compact: Bool { false }
    private func move(_ direction: MoveCommandDirection) {
        switch direction {
        case .left: model.focusLeft()
        case .right: model.focusRight()
        case .up: model.focusUp()
        case .down: model.focusDown()
        @unknown default: break
        }
    }

    private func activateFocused() {
        guard let focus = model.focus, model.rows.indices.contains(focus.rowIndex) else { return }
        activate(focus.cell, row: model.rows[focus.rowIndex])
    }
    #else
    private var compact: Bool { sizeClass == .compact }
    private var scrollDrag: some Gesture {
        DragGesture()
            .onChanged {
                model.scrollTime(byPoints: dragAnchor - $0.translation.width)
                dragAnchor = $0.translation.width
            }
            .onEnded { _ in dragAnchor = 0 }
    }
    #endif
}

/// Identifies the channel being tuned from the grid (drives the fullscreen cover).
private struct GuidePlaybackTarget: Identifiable {
    let id: Int
    let url: String
}
