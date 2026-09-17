import Foundation

/// Composition-root wiring for the My List screen, split out of ``AppEnvironment``
/// to keep each factory file within budget (the `+VodFactory` precedent). The
/// My List store shares the channel store's DB handle (the Custom-Groups
/// DB-handle pattern), so `AppEnvironment` need not gain a stored property.
extension AppEnvironment {
    /// The My List screen's observable state over the `my_list` store bound to
    /// the shared database handle, the wall clock, and the local time zone.
    func makeMyListModel() -> MyListModel {
        MyListModel(store: MyListStore(db: channelStore.db),
                    channelStore: channelStore,
                    now: clock, timeZone: .current)
    }
}
