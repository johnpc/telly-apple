import SwiftUI

/// The recently-watched channels screen: a list of the channels most recently
/// tuned (newest first), reusing the same ``ChannelListRowView`` as the channel
/// list. Selecting a row opens the live player via the identical
/// `.fullScreenCover` path `ChannelListScreen` uses; the toolbar trash button
/// clears the history. Pure presentation — logic lives in ``HistoryListModel``.
struct HistoryScreen: View {
    @State private var model: HistoryListModel
    let makeEngine: () -> VLCKitPlayerEngine
    @State private var target: HistoryPlaybackTarget?

    init(model: HistoryListModel, makeEngine: @escaping () -> VLCKitPlayerEngine) {
        _model = State(initialValue: model)
        self.makeEngine = makeEngine
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
            .fullScreenCover(item: $target) { target in
                PlaybackScreen(streamUrl: target.url, engine: makeEngine())
            }
    }

    /// Shown when nothing has been watched yet so the empty List isn't blank.
    @ViewBuilder private var emptyState: some View {
        if model.rows.isEmpty {
            ContentUnavailableView("No history", systemImage: "clock.arrow.circlepath")
        }
    }

    @ViewBuilder private func row(_ channel: ChannelEntity) -> some View {
        Button {
            target = HistoryPlaybackTarget(id: channel.id, url: channel.source.streamUrl)
        } label: {
            ChannelListRowView(channel: channel)
        }
        .buttonStyle(.plain)
    }
}

/// Identifies the channel currently being played (drives the fullscreen cover).
private struct HistoryPlaybackTarget: Identifiable {
    let id: Int
    let url: String
}
