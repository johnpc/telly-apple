import CoreGraphics
import Foundation

/// The guide grid's observable state + actions: snapshots the visible channels,
/// floors "now" to the window origin, materialises the rows for the current
/// scroll window (via the pure `GuideWindowMath`/`GuideRowsBuilder`/`GuideFocusNav`
/// maths), and drives scroll/select/focus. `now` is injected; `nowMs` snapshots
/// it so the view's per-minute `tick()` advances the now-line. `+Focus` for focus.
@MainActor
@Observable
final class GuideGridModel {
    /// Days of past EPG the grid may scroll back into (mirrors the EPG keep-past
    /// horizon); the forward horizon lives in `GuideWindowMath.forwardDays`.
    static let pastDays = 7

    private let channelStore: ChannelStore
    private let repository: EpgRepository
    let now: () -> Int
    let timeZone: TimeZone
    let is24h: Bool
    /// Width in points of the programme pane; only `setViewport` mutates it.
    var viewport: CGFloat

    private(set) var originMs = 0
    private(set) var scrollX: CGFloat = 0
    private(set) var rows: [GuideRow] = []
    private(set) var channels: [ChannelEntity] = []
    private(set) var focus: GuideFocus?
    var nowMs = 0  // clock the now-line tracks; `tick()` (in `+View`) refreshes it

    init(channelStore: ChannelStore, repository: EpgRepository, now: @escaping () -> Int,
         timeZone: TimeZone, is24h: Bool, viewport: CGFloat = 960) {
        self.channelStore = channelStore
        self.repository = repository
        self.now = now
        self.timeZone = timeZone
        self.is24h = is24h
        self.viewport = viewport
    }

    /// Snapshots the visible channels, floors the clock to the origin, and
    /// materialises the first window of rows + initial focus.
    func load() {
        channels = (try? channelStore.visibleChannels()) ?? []
        originMs = GuideGeometry.halfHourFloor(now(), timeZone: timeZone)
        nowMs = now()
        materializeRows()
    }

    /// Rebuilds the rows for the current window (offsets via the shared
    /// `EpgOffsets.map(for:)` helper), then re-derives a stable focus.
    func materializeRows() {
        let offsets = EpgOffsets.map(for: channels)
        let epgIds = channels.compactMap(\.epgId)
        let span = GuideWindowMath.materializeSpan(
            originMs: originMs, scrollX: scrollX, viewport: viewport)
        let programs = (try? repository.programs(
            tvgIds: epgIds, fromMs: span.fromMs, toMs: span.toMs, offsets: offsets)) ?? []
        rows = GuideRowsBuilder.build(channels: channels, programs: programs, span: span)
        focus = GuideFocusNav.resolve(rows: rows, nowMs: now(), current: focus)
    }

    /// Pans the timeline by `delta` points, clamped to the horizon, then re-materialises.
    func scrollTime(byPoints delta: CGFloat) {
        scrollX = clampScroll(scrollX + delta)
        materializeRows()
    }

    /// Re-anchors the scroll to the now column (the origin sits at `scrollX == 0`).
    func jumpToNow() {
        scrollX = 0
        materializeRows()
    }

    /// Activation delegates to the pure `GuideActivation` (catch-up-first).
    func selectCell(_ cell: GuideCell, row: GuideRow) -> GuideSelection {
        GuideActivation.activate(row: row, cell: cell, nowMs: now())
    }

    /// Sets focus to `cell` on `rowIndex`, pans it into view, then re-materialises.
    func applyFocus(rowIndex: Int, cell: GuideCell, anchorMs: Int) {
        focus = GuideFocus(rowIndex: rowIndex, cell: cell, anchorMs: anchorMs)
        scrollX = clampScroll(pannedScroll(toShow: cell))
        materializeRows()
    }

    /// The scroll offset bringing `cell` on-screen, panning only at a viewport edge.
    private func pannedScroll(toShow cell: GuideCell) -> CGFloat {
        let left = GuideGeometry.xOf(cell.startMs, originMs: originMs)
        let right = GuideGeometry.xOf(cell.endMs, originMs: originMs)
        if left < scrollX { return left }
        if right > scrollX + viewport { return right - viewport }
        return scrollX
    }

    private func clampScroll(_ x: CGFloat) -> CGFloat {
        min(max(x, GuideWindowMath.scrollFloor(pastDays: Self.pastDays)),
            GuideWindowMath.scrollCeil())
    }
}
