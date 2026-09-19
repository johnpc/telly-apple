import SwiftUI

/// The channel list's phase-aware body: the group strip + list once loaded,
/// otherwise the shared skeleton / empty / error+retry treatment. Split out so
/// `ChannelListScreen` stays within the source-line budget. The scaffold and the
/// group strip are factored so the iPad split sidebar (`+Split`) reuses them
/// without a copy. Retry re-invokes the model's real reload seam, never a copy.
extension ChannelListScreen {
    var loadStateContent: some View {
        channelLoadScaffold {
            VStack(spacing: 0) {
                groupPicker
                List(model.rows, id: \.id) { channel in row(channel) }
            }
        }
    }

    /// The loaded-state wrapper both layouts share: skeleton while loading, a
    /// tailored empty state, error+Retry on failure, else the caller's content.
    func channelLoadScaffold<Content: View>(
        @ViewBuilder _ content: @escaping () -> Content
    ) -> some View {
        LoadStateScaffold(
            phase: model.phase,
            emptyTitle: "No channels",
            emptySystemImage: "tv.slash",
            emptyMessage: "This playlist has no channels yet.",
            retry: { Task { await model.retry() } },
            content: content
        )
    }

    /// The horizontal group filter strip shared by the stack list and the split
    /// sidebar.
    var groupPicker: some View {
        ChannelGroupPickerView(groups: model.groups, selected: model.selectedGroup,
                               onSelect: model.select)
    }
}
