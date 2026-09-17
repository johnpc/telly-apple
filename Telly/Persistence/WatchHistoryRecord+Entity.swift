import Foundation

extension WatchHistoryRecord {
    /// Builds a persistence row from a domain entry (epoch millis widen
    /// `Int` => `Int64` at the row boundary, as `ProgramRecord` does).
    init(_ e: WatchHistoryEntry) {
        self.init(channelKey: e.channelKey, watchedAtMs: Int64(e.watchedAtMs))
    }

    /// The domain entry this row represents (narrows `Int64` => `Int`).
    var entity: WatchHistoryEntry {
        WatchHistoryEntry(channelKey: channelKey, watchedAtMs: Int(watchedAtMs))
    }
}

/// One recently-watched channel: its refresh-stable key and when it was tuned.
struct WatchHistoryEntry: Equatable {
    let channelKey: String
    let watchedAtMs: Int
}
