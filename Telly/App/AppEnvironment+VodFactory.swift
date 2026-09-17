import Foundation

/// Composition-root wiring for the Movies browser, split out of ``AppEnvironment``
/// to keep each factory file within budget (the `+CatchupFactory` precedent). The
/// VOD stores share the channel store's DB handle (the Custom-Groups DB-handle
/// pattern); the `remember` seam defaults to `true` until Slice 6 wires the real
/// "Remember playback position" setting. The playback-model factory lands with
/// the playback model itself in a later slice.
extension AppEnvironment {
    /// The Movies browser's observable state over VOD item + position stores
    /// bound to the shared database handle.
    func makeVodBrowseModel() -> VodBrowseModel {
        VodBrowseModel(itemStore: VodItemStore(db: channelStore.db),
                       positionStore: makeVodPositionStore())
    }

    /// The resume-position store on the shared handle, `remember` defaulted on
    /// until settings wiring; also used by the debug fixture seeder.
    func makeVodPositionStore() -> VodPositionStore {
        VodPositionStore(db: channelStore.db, remember: { true },
                         clock: { [clock] in Int64(clock()) })
    }

    /// A VOD playback model over a fresh VLCKit engine and the shared-handle
    /// stores; `onExit` dismisses the presenting cover and reloads the browser.
    /// Does NOT auto-start — the screen calls `start` in `.task`.
    func makeVodPlaybackModel(itemKey: String, onExit: @escaping () -> Void) -> VodPlaybackModel {
        VodPlaybackModel(engine: VLCKitPlayerEngine(),
                         itemStore: VodItemStore(db: channelStore.db),
                         positionStore: makeVodPositionStore(),
                         itemKey: itemKey, now: clock, onExit: onExit)
    }
}
