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

    let channelStore: ChannelStore
    private let repository: EpgRepository
    /// Hides channels in disabled playlist groups; identity unless the composition
    /// root wires the shared `PlaylistGroupFilter` in (channel-list/guide-feed parity).
    private let filter: ([ChannelEntity]) -> [ChannelEntity]
    /// User-created custom groups, reloaded with the channels so the group strip
    /// lists them after the playlist groups (channel-list parity).
    var customGroups: [CustomGroup] = []
    /// The interactive group-chip selection; "All channels" until the user picks
    /// another (not persisted, matching the channel list). `+Groups` filters `rows`.
    var selectedGroup = ChannelPanelGroups.allChannels
    /// Pseudo-group visibility, mirroring the channel list's Appearance toggles.
    var visibility = GroupVisibility.standard
    let now: () -> Int
    let timeZone: TimeZone
    let is24h: Bool
    /// The persisted channel-sort (snapshotted at build, like `is24h`).
    let sort: ChannelSort
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
    /// The My List store, bound post-init by the factory (like `refresh`), so the
    /// init signature stays put; nil in tests/previews makes the cell menu a no-op.
    var myListStore: MyListStore?
    /// Saved-airing identity keys backing the cell menu's flipped label (My List state).
    var myListKeys: Set<String> = []

    init(channelStore: ChannelStore, repository: EpgRepository, now: @escaping () -> Int,
         timeZone: TimeZone, is24h: Bool, viewport: CGFloat = 960,
         sort: ChannelSort = .default,
         filter: @escaping ([ChannelEntity]) -> [ChannelEntity] = { $0 }) {
        self.channelStore = channelStore
        self.repository = repository
        self.filter = filter
        self.now = now
        self.timeZone = timeZone
        self.is24h = is24h
        self.sort = sort
        self.viewport = viewport
    }

    /// Snapshots the visible channels, floors the clock to the origin, and
    /// materialises the first window of rows + initial focus.
    func load() {
        channels = filter((try? channelStore.visibleChannels()) ?? [])
        customGroups = (try? CustomGroupStore(db: channelStore.db).all()) ?? []
        originMs = GuideGeometry.halfHourFloor(now(), timeZone: timeZone)
        nowMs = now()
        materializeRows()
        refreshMyListKeys()
    }

    /// Rebuilds the rows for the current window (offsets via the shared
    /// `EpgOffsets.map(for:)` helper), then re-derives a stable focus.
    func materializeRows() {
        let visible = selectedChannels
        let offsets = EpgOffsets.map(for: visible)
        let epgIds = visible.compactMap(\.epgId)
        let span = GuideWindowMath.materializeSpan(
            originMs: originMs, scrollX: scrollX, viewport: viewport)
        let programs = (try? repository.programs(
            tvgIds: epgIds, fromMs: span.fromMs, toMs: span.toMs, offsets: offsets)) ?? []
        rows = GuideRowsBuilder.build(channels: visible, programs: programs, span: span)
        focus = GuideFocusNav.resolve(rows: rows, nowMs: now(), current: focus)
    }

    /// Activation delegates to the pure `GuideActivation` (catch-up-first).
    func selectCell(_ cell: GuideCell, row: GuideRow) -> GuideSelection {
        GuideActivation.activate(row: row, cell: cell, nowMs: now())
    }
}
