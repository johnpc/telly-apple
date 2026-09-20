import SwiftUI

/// The guide grid's group-filter chip strip, reusing the channel list's
/// `ChannelGroupPickerView` so it looks and behaves identically (scrollable, tvOS
/// focusable, compact auto-scroll). Sits atop the grid; picking a group re-filters
/// the visible channel rows + their programme lanes live via `selectGroup`.
extension GuideGridScreen {
    var groupStrip: some View {
        ChannelGroupPickerView(groups: model.groups, selected: model.selectedGroup,
                               onSelect: model.selectGroup)
    }
}
