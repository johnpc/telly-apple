import SwiftUI

/// The recently-watched channels screen: a list of the channels most recently
/// tuned (newest first), reusing the same ``ChannelListRowView`` as the channel
/// list. Selecting a row opens the SHARED live stage via the identical
/// `.liveStageCover` path the home screen uses — the SAME persistent engine, so
/// re-entering a channel never reconnects. The toolbar trash button clears the
/// history. Pure presentation — logic lives in ``HistoryListModel``.
struct HistoryScreen: View {
    @State var model: HistoryListModel
    let liveStage: LiveStagePresentation
    @State var target: LiveStageTarget?

    var body: some View {
        LoadableScaffold(model: model, empty: EmptyCopy(
            title: "No history", systemImage: "clock.arrow.circlepath",
            message: "Channels you watch will appear here, newest first.")) {
            List(model.rows, id: \.id) { channel in row(channel) }
        }
        .navigationTitle("History")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Clear", systemImage: "trash") { model.clear() }
            }
        }
        .task { await model.start() }
        .liveStageCover($target, using: liveStage)
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
