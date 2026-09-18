import SwiftUI

/// The TiviMate-style guide grid (dark on tvOS, the app's system scheme on
/// iPhone/iPad): a fixed left channel column beside a pane whose header/strips/
/// now-line pan off `scrollX`, its viewport derived from available width
/// (`setViewport`). tvOS D-pad; iPhone/iPad drag+tap.
struct GuideGridScreen: View {
    @State var model: GuideGridModel
    let makeEngine: () -> VLCKitPlayerEngine
    let makeCatchupModel: (CatchupRequest) -> CatchupPlaybackModel
    #if !os(tvOS)
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var dragAnchor: CGFloat = 0
    #endif
    @State var target: GuidePlaybackTarget?

    init(model: GuideGridModel, makeEngine: @escaping () -> VLCKitPlayerEngine,
         makeCatchupModel: @escaping (CatchupRequest) -> CatchupPlaybackModel) {
        _model = State(initialValue: model)
        self.makeEngine = makeEngine
        self.makeCatchupModel = makeCatchupModel
    }

    var body: some View {
        GeometryReader { geo in
            gridScaffold
                .task(id: geo.size.width) { model.setViewport(geo.size.width - columnWidth) }
        }
        .guideSurface()
        .task { await model.start() }
        .guideMinuteTick { model.tick() }
        .fullScreenCover(item: $target) { playbackCover($0) }
        #if os(tvOS)
        .focusable()
        .onMoveCommand { move($0) }
        .onTapGesture { activateFocused() }
        #endif
    }

    /// Loaded content is the header + panning grid; loading/empty/error defer to
    /// the shared skeleton / empty / error+retry treatment (Retry re-runs the EPG refresh).
    private var gridScaffold: some View {
        LoadStateScaffold(phase: model.phase, emptyTitle: "No channels",
                          emptySystemImage: "tv.slash", emptyMessage: "Nothing to show in the guide yet.",
                          retry: { Task { await model.retry() } }) {
            VStack(spacing: 0) { header; grid }
        }
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
                GuideChannelColumnView(rows: model.rows, width: columnWidth,
                                       compact: compact, activeRowIndex: activeRow)
                GuideRowsPaneView(model: model, compact: compact, onActivate: activate)
            }
        }
        #if !os(tvOS)
        .highPriorityGesture(scrollDrag)
        #endif
    }

    private var columnWidth: CGFloat { compact ? 168 : GuideGeometry.channelColumnWidth }
    #if os(tvOS)
    private var compact: Bool { false }
    /// The focused row whose channel name marquees (D-pad focus is the cursor).
    private var activeRow: Int? { model.focus?.rowIndex }
    #else
    private var compact: Bool { sizeClass == .compact }
    /// No D-pad cursor off tvOS — the pointer hover drives the marquee per tile.
    private var activeRow: Int? { nil }
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
