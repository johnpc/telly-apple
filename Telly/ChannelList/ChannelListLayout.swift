import SwiftUI

/// Pure layout-selection for the channel list. On a wide canvas (iPad regular
/// width) the list earns a two-column split — a sidebar of channels beside a
/// detail pane — while compact iPhone and tvOS keep the single stacked list.
/// Kept free of view code so the split decision, and the selected-channel the
/// detail pane binds to, are unit-tested rather than left to visual capture.
enum ChannelListLayout {
    /// True when the canvas is wide enough for the sidebar + detail split. Only
    /// the regular horizontal size class (iPad, and large-iPhone landscape)
    /// qualifies; compact stays a single column. tvOS never routes through here.
    static func usesSplit(_ sizeClass: UserInterfaceSizeClass?) -> Bool {
        sizeClass == .regular
    }

    /// The channel the detail pane shows: the row whose id matches the current
    /// selection, else the first row (so a freshly loaded split never shows an
    /// empty pane), else nil when there are no rows at all.
    static func selectedChannel(in rows: [ChannelEntity], id: Int?) -> ChannelEntity? {
        if let id, let match = rows.first(where: { $0.id == id }) { return match }
        return rows.first
    }
}
