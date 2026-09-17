import Foundation

/// The My List screen's observable state: the saved programmes still airing or
/// yet to air, newest-added first. `load` reads snapshots from the
/// ``MyListStore`` and resolves them to current `ChannelEntity`s via the pure
/// ``MyListRows`` join (dropping keys no longer visible, hiding ended airings);
/// `remove` deletes one entry and republishes. Logic lives here so
/// ``MyListScreen`` stays pure SwiftUI — the Apple mirror of Android's
/// `MyListViewModel`.
@MainActor
@Observable
final class MyListModel {
    let store: MyListStore
    let channelStore: ChannelStore
    let now: () -> Int
    let timeZone: TimeZone
    var rows: [MyListRow] = []

    init(store: MyListStore, channelStore: ChannelStore,
         now: @escaping () -> Int, timeZone: TimeZone) {
        self.store = store
        self.channelStore = channelStore
        self.now = now
        self.timeZone = timeZone
    }

    /// (Re)loads the saved programmes, joined newest-added-first to the visible
    /// channels with ended airings hidden and the airing-now row flagged.
    func load() {
        let entries = (try? store.all()) ?? []
        let channels = (try? channelStore.visibleChannels()) ?? []
        rows = MyListRows.rows(entries: entries, channels: channels,
                               nowMs: now(), timeZone: timeZone)
    }

    /// Removes one saved programme (by its identity `(channelKey, startMs)`)
    /// and republishes the remaining rows.
    func remove(_ row: MyListRow) {
        try? store.remove(channelKey: row.entry.channelKey, startMs: row.entry.startMs)
        load()
    }
}
