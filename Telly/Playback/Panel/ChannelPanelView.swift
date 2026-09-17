import SwiftUI

/// The in-playback channel panel over the dimmed video: a groups selector beside
/// (tvOS / regular width) or above (compact iPhone) a scrolling now-playing
/// channel list, opened by DOWN from the info overlay. D-pad routing is a later
/// slice; the initial focus is seeded on the playing channel so the render is
/// deterministic. Ported from the Android channel panel. Pure presentation — all
/// derivation lives in ``ChannelPanelGroups`` / ``PanelRowBuilder`` /
/// ``PanelSelection``.
struct ChannelPanelView: View {
    let channels: [ChannelEntity]
    let current: ChannelEntity?
    let nowNext: (ChannelEntity) -> NowNext?
    let nowMs: Int
    /// User-created custom groups, appended after the playlist groups in the
    /// group column (Android parity); empty by default so existing call sites
    /// compile unchanged.
    var customGroups: [CustomGroup] = []
    #if !os(tvOS)
    @Environment(\.horizontalSizeClass) private var sizeClass
    #endif

    private var groups: [String] { ChannelPanelGroups.groupNames(channels, customs: customGroups) }

    private var rows: [PanelRowInfo] {
        PanelRowBuilder.rows(channels, group: ChannelPanelGroups.allChannels,
                             nowNext: nowNext, nowMs: nowMs)
    }

    private var selection: PanelSelection {
        PanelSelection.initial(groups: groups.count, rows: rows.count,
                               selectedRow: playingIndex)
    }

    private var playingIndex: Int {
        channels.firstIndex { $0.id == current?.id } ?? 0
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            layout.padding(24)
        }
    }

    #if os(tvOS)
    private var layout: some View { wide }
    #else
    @ViewBuilder private var layout: some View {
        if sizeClass == .compact { stacked } else { wide }
    }

    private var stacked: some View {
        VStack(alignment: .leading, spacing: 16) {
            ChannelPanelGroupsColumnView(groups: groups, selectedIndex: selection.groupIndex,
                                         horizontal: true)
            ChannelPanelRowsColumnView(rows: rows, focusedIndex: selection.rowIndex)
        }
    }
    #endif

    private var wide: some View {
        HStack(alignment: .top, spacing: 24) {
            ChannelPanelGroupsColumnView(groups: groups, selectedIndex: selection.groupIndex)
            ChannelPanelRowsColumnView(rows: rows, focusedIndex: selection.rowIndex)
        }
    }
}
