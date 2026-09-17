import Foundation

/// The recently-watched screen's observable state: the visible channels most
/// recently tuned, newest first. `load` reads raw events from the
/// `WatchHistoryStore` and resolves them to current `ChannelEntity`s via the
/// pure ``WatchHistoryRows`` join (dropping keys no longer visible after a
/// refresh); `clear` empties the store and republishes. Logic lives here so
/// ``HistoryScreen`` stays pure SwiftUI — the Apple mirror of Android's history
/// view-model.
@MainActor
@Observable
final class HistoryListModel {
    let store: WatchHistoryStore
    let channelStore: ChannelStore
    var rows: [ChannelEntity] = []

    init(store: WatchHistoryStore, channelStore: ChannelStore) {
        self.store = store
        self.channelStore = channelStore
    }

    /// (Re)loads the recently-watched channels, joined newest-first to the
    /// currently visible channels.
    func load() {
        let events = (try? store.recent()) ?? []
        let channels = (try? channelStore.visibleChannels()) ?? []
        rows = WatchHistoryRows.rows(events: events, channels: channels)
    }

    /// Empties the history and republishes the (now empty) rows.
    func clear() {
        try? store.clear()
        load()
    }
}
