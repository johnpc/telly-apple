import SwiftUI

/// The recently-watched channels screen: a list of the channels most recently
/// tuned (newest first), reusing the same ``ChannelListRowView`` as the channel
/// list. Selecting a row opens the SHARED live stage via the identical
/// `.liveStageCover` path the home screen uses — the SAME persistent engine, so
/// re-entering a channel never reconnects. The toolbar trash button clears the
/// history. Pure presentation — logic lives in ``HistoryListModel``.
struct HistoryScreen: View {
    @State private var model: HistoryListModel
    let liveStage: LiveStagePresentation
    @State private var target: LiveStageTarget?

    init(model: HistoryListModel, liveStage: LiveStagePresentation) {
        _model = State(initialValue: model)
        self.liveStage = liveStage
    }

    var body: some View {
        List(model.rows, id: \.id) { channel in row(channel) }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Clear", systemImage: "trash") { model.clear() }
                }
            }
            .overlay { emptyState }
            .task { model.load() }
            .liveStageCover($target, using: liveStage)
    }

    /// Shown when nothing has been watched yet so the empty List isn't blank.
    @ViewBuilder private var emptyState: some View {
        if model.rows.isEmpty {
            ContentUnavailableView("No history", systemImage: "clock.arrow.circlepath")
        }
    }

    @ViewBuilder private func row(_ channel: ChannelEntity) -> some View {
        Button {
            target = LiveStageTarget(channel: channel)
        } label: {
            ChannelListRowView(channel: channel)
        }
        .buttonStyle(.plain)
    }
}
