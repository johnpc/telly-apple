import SwiftUI

/// The My List screen: saved programmes newest-added first (``MyListRowView``).
/// Tapping an airing row tunes its channel via the identical `.fullScreenCover`
/// path the channel list uses; tapping a future row shows its description in a
/// sheet (Android's overlay). Rows remove via a swipe action (iOS/iPadOS) and a
/// context menu (tvOS-safe). No clear-all — Android's my_list has none. Pure
/// presentation; logic lives in ``MyListModel``.
struct MyListScreen: View {
    @State private var model: MyListModel
    let makeEngine: () -> VLCKitPlayerEngine
    @State private var target: MyListPlaybackTarget?
    @State private var described: MyListRow?

    init(model: MyListModel, makeEngine: @escaping () -> VLCKitPlayerEngine) {
        _model = State(initialValue: model)
        self.makeEngine = makeEngine
    }

    var body: some View {
        List(model.rows) { row in rowView(row) }
            .navigationTitle("My List")
            .overlay { emptyState }
            .task { model.load() }
            .fullScreenCover(item: $target) { target in
                PlaybackScreen(streamUrl: target.url, engine: makeEngine())
            }
            .sheet(item: $described) { row in descriptionSheet(row) }
    }

    /// Shown when nothing is saved yet so the empty List isn't blank.
    @ViewBuilder private var emptyState: some View {
        if model.rows.isEmpty {
            ContentUnavailableView("No saved programmes", systemImage: "bookmark")
        }
    }

    @ViewBuilder private func rowView(_ row: MyListRow) -> some View {
        let button = Button { open(row) } label: { MyListRowView(row: row) }
            .buttonStyle(.plain)
            .contextMenu { removeButton(row) }
        #if os(tvOS)
        button
        #else
        button.swipeActions { removeButton(row) }
        #endif
    }

    private func removeButton(_ row: MyListRow) -> some View {
        Button("Remove", systemImage: "trash", role: .destructive) { model.remove(row) }
    }

    private func open(_ row: MyListRow) {
        if row.airing {
            target = MyListPlaybackTarget(id: row.channel.id, url: row.channel.source.streamUrl)
        } else {
            described = row
        }
    }

    @ViewBuilder private func descriptionSheet(_ row: MyListRow) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(row.entry.title).font(.headline)
            if let text = row.entry.description, !text.isEmpty { Text(text) }
        }
        .padding()
    }
}

/// Makes a My List row addressable by `List`/`.sheet(item:)` via its identity.
extension MyListRow: Identifiable {
    var id: String { MyListToggle.key(channelKey: entry.channelKey, startMs: entry.startMs) }
}

/// Identifies the channel currently being tuned (drives the fullscreen cover).
private struct MyListPlaybackTarget: Identifiable {
    let id: Int
    let url: String
}
