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
    /// Pan offset + focus cursor: mutated by the pan/focus actions in the sibling
    /// `+Scroll`/`+Focus` files, so their setters are module-internal (not file-private).
    var scrollX: CGFloat = 0
    private(set) var rows: [GuideRow] = []
    private(set) var channels: [ChannelEntity] = []
    var focus: GuideFocus?
    var nowMs = 0  // clock the now-line tracks; `tick()` (in `+View`) refreshes it
    /// The grid's load lifecycle: `loading` until the first materialise resolves
    /// to `loaded`/`empty`, or `failed` when an empty grid's EPG refresh threw.
    var phase: LoadPhase = .loading
    /// EPG refresh seam awaited on first appear (when empty) and on Retry; the
    /// composition root wires the real forced refresh (`+Load`).
    var refresh: () async throws -> Void = {}

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

    /// Activation delegates to the pure `GuideActivation` (catch-up-first).
    func selectCell(_ cell: GuideCell, row: GuideRow) -> GuideSelection {
        GuideActivation.activate(row: row, cell: cell, nowMs: now())
    }
}
