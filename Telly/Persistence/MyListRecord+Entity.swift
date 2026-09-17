import Foundation

extension MyListRecord {
    /// Builds a persistence row from a domain entry (epoch millis widen
    /// `Int` => `Int64` at the row boundary, as `WatchHistoryRecord` does).
    init(_ e: MyListEntry) {
        self.init(channelKey: e.channelKey, startMs: Int64(e.startMs),
                  endMs: Int64(e.endMs), title: e.title, description: e.description,
                  addedAtMs: Int64(e.addedAtMs))
    }

    /// The domain entry this row represents (narrows `Int64` => `Int`).
    var entity: MyListEntry {
        MyListEntry(channelKey: channelKey, startMs: Int(startMs), endMs: Int(endMs),
                    title: title, description: description, addedAtMs: Int(addedAtMs))
    }
}

/// One saved programme: a snapshot of the airing (title/description/times) plus
/// a reference to its channel via the refresh-stable `channelKey`. Identity is
/// `(channelKey, startMs)`; `addedAtMs` drives the newest-added-first order.
struct MyListEntry: Equatable {
    let channelKey: String
    let startMs: Int
    let endMs: Int
    let title: String
    let description: String?
    let addedAtMs: Int
}
