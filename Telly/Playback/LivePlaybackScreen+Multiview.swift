import SwiftUI

/// The pane-menu and channel-picker layers stacked over the multiview grid, split
/// out of ``LivePlaybackScreen+Overlays`` so both stay within the source-line
/// budget. Each shows only while the `.multiview` overlay is up and its session
/// sub-state is set (menu or picker), leaving the grid rendered underneath. Row
/// activation routes straight to the model, which mutates the session's engines.
extension LivePlaybackScreen {
    @ViewBuilder var multiviewMenuOverlay: some View {
        if case .multiview = model.overlay, let session = model.multiview, let menu = session.menu {
            MultiviewPaneMenuView(rows: session.menuRows, selection: menu.selection,
                                  onSelect: { model.runMultiviewMenuRow($0) })
                .overlayTransition(reduceMotion: reduceMotion)
        }
    }

    @ViewBuilder var multiviewPickerOverlay: some View {
        if case .multiview = model.overlay, let session = model.multiview, let picker = session.picker {
            MultiviewChannelPickerView(channels: model.multiviewPickerChannels,
                                       selection: picker.selection, title: picker.mode.title,
                                       onSelect: { model.selectMultiviewChannel($0) })
                .overlayTransition(reduceMotion: reduceMotion)
        }
    }
}
