import SwiftUI

/// The My List screen: saved programmes newest-added first (``MyListRowView``).
/// Tapping an airing row tunes its channel via the identical `.liveStageCover`
/// path the channel list uses (the SAME persistent live engine — no reconnect);
/// tapping a future row shows its description in a sheet (Android's overlay).
/// Rows remove via a swipe action (iOS/iPadOS) and a context menu (tvOS-safe).
/// No clear-all — Android's my_list has none. Pure presentation; logic lives in
/// ``MyListModel``.
struct MyListScreen: View {
    @State var model: MyListModel
    let liveStage: LiveStagePresentation
    @State var target: LiveStageTarget?
    @State var described: MyListRow?

    var body: some View {
        LoadableScaffold(model: model, empty: EmptyCopy(
            title: "No saved programmes", systemImage: "bookmark",
            message: "Save a programme from the guide or search to see it here.")) {
            List(model.rows) { row in rowView(row) }
        }
        .navigationTitle("My List")
        .task { await model.start() }
        .liveStageCover($target, using: liveStage)
        .sheet(item: $described) { row in descriptionSheet(row) }
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
            target = LiveStageTarget(channel: row.channel)
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
