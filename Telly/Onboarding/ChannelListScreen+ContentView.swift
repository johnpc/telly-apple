import SwiftUI

/// The channel list's phase-aware body: the group strip + list once loaded,
/// otherwise the shared skeleton / empty / error+retry treatment. Split out so
/// `ChannelListScreen` stays within the source-line budget. Retry re-invokes the
/// model's real reload seam (the injected playlist refresh), never a copy.
extension ChannelListScreen {
    var loadStateContent: some View {
        LoadStateScaffold(
            phase: model.phase,
            emptyTitle: "No channels",
            emptySystemImage: "tv.slash",
            emptyMessage: "This playlist has no channels yet.",
            retry: { Task { await model.retry() } }
        ) {
            VStack(spacing: 0) {
                ChannelGroupPickerView(groups: model.groups, selected: model.selectedGroup,
                                       onSelect: model.select)
                List(model.rows, id: \.id) { channel in row(channel) }
            }
        }
    }
}
