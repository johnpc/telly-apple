import SwiftUI

/// The TiviMate-style guide grid (dark on tvOS, the app's system scheme on
/// iPhone/iPad): a fixed left channel column beside a pane whose header/strips/
/// now-line pan off `scrollX`, its viewport derived from available width
/// (`setViewport`). tvOS D-pad; iPhone/iPad drag+tap.
struct GuideGridScreen: View {
    @State var model: GuideGridModel
    let makeEngine: () -> VLCKitPlayerEngine
    let makeCatchupModel: (CatchupRequest) -> CatchupPlaybackModel
    /// Overlay mode: when set, an airing cell tunes the SHARED engine (nil pushes).
    let onLiveTune: ((ChannelEntity) -> Void)?
    #if !os(tvOS)
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var dragAnchor: CGFloat = 0
    #endif
    @State var target: GuidePlaybackTarget?
    /// The cell whose program info panel is open (set by `activate`, `+Activate`).
    @State var infoTarget: GuideInfoTarget?
    /// Which focus region owns the remote (tvOS): the grid cursor or the day chrome.
    @FocusState var focusArea: GuideFocusArea?

    init(model: GuideGridModel, makeEngine: @escaping () -> VLCKitPlayerEngine,
         makeCatchupModel: @escaping (CatchupRequest) -> CatchupPlaybackModel,
         onLiveTune: ((ChannelEntity) -> Void)? = nil) {
        _model = State(initialValue: model)
        self.makeEngine = makeEngine
        self.makeCatchupModel = makeCatchupModel
        self.onLiveTune = onLiveTune
    }

    var body: some View {
        GeometryReader { geo in
            gridScaffold
                .task(id: geo.size.width) { model.setViewport(geo.size.width - columnWidth) }
        }
        .guideSurface()
        .task { await model.start() }
        .ticking(every: 60) { model.tick() }
        .fullScreenCover(item: $target) { playbackCover($0) }
        .guideProgramInfo($infoTarget, model: model, onPlay: play)
        #if DEBUG
        .task { await GuideMenuScreenshotSeed.present($infoTarget, model: model) }
        #endif
    }

    /// Loaded content is the header + panning grid; loading/empty/error defer to
    /// the shared skeleton / empty / error+retry treatment (Retry re-runs the EPG refresh).
    private var gridScaffold: some View {
        LoadableScaffold(model: model, empty: EmptyCopy(
            title: "No channels", systemImage: "tv.slash", message: "Nothing to show in the guide yet.")) {
            VStack(spacing: 0) { groupStrip; dayNavBar; gridBody }
        }
    }

    var grid: some View {
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

    var columnWidth: CGFloat { compact ? 168 : GuideGeometry.channelColumnWidth }
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
