import Foundation

/// Composition-root wiring for the Movies browser, split out of ``AppEnvironment``
/// to keep each factory file within budget (the `+CatchupFactory` precedent). The
/// VOD stores share the channel store's DB handle (the Custom-Groups DB-handle
/// pattern); the `remember` seam reads the "Remember playback position" setting,
/// and `clearVodPositions` empties the store for the Settings clear action.
extension AppEnvironment {
    /// The Movies browser's observable state over VOD item + position stores
    /// bound to the shared database handle.
    func makeVodBrowseModel() -> VodBrowseModel {
        VodBrowseModel(itemStore: VodItemStore(db: channelStore.db),
                       positionStore: makeVodPositionStore())
    }

    /// The resume-position store on the shared handle, gated by the real
    /// "Remember playback position" setting; also used by the debug seeder.
    func makeVodPositionStore() -> VodPositionStore {
        VodPositionStore(db: channelStore.db,
                         remember: { [settings] in settings.vodRememberPosition },
                         clock: { [clock] in Int64(clock()) })
    }

    /// Empties every stored VOD position (Settings → Clear playback positions),
    /// reporting success/failure so the Settings control can confirm it.
    @discardableResult
    func clearVodPositions() -> UpdateOutcome {
        let ok = (try? makeVodPositionStore().clear()) != nil
        return .done(ok, success: "Playback positions cleared", failure: "Couldn’t clear positions")
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
