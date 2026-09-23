import Foundation

/// The composition-root wiring for catch-up transport, split out of
/// ``AppEnvironment`` to keep each factory file within budget. Thin device glue
/// (like ``makeLivePlaybackModel``): a fresh VLCKit engine plus the neighbour /
/// live-edge cores bound to the real EPG repository and wall clock.
extension AppEnvironment {
    /// A catch-up transport model over a fresh engine, its hop cores wired to the
    /// real EPG repository. Offsets are omitted here (v1: hop over unshifted
    /// times is acceptable; composing the guide's per-channel offsets is a later
    /// refinement). Does NOT auto-start — the screen calls `start` in `.task`.
    func makeCatchupPlaybackModel(request: CatchupRequest) -> CatchupPlaybackModel {
        let repository = EpgRepository(store: programStore)
        return CatchupPlaybackModel(
            engine: makeEngine(),
            neighbours: CatchupNeighbours(
                programs: { tvgIds, fromMs, toMs in
                    (try? repository.programs(tvgIds: tvgIds, fromMs: fromMs,
                                              toMs: toMs, offsets: [:])) ?? []
                },
                clock: clock),
            liveEdge: CatchupLiveEdge(
                nowNext: { tvgId, atMs in
                    (try? repository.nowNext(tvgIds: [tvgId], atMs: atMs, offsets: [:]))?[tvgId]
                },
                clock: clock),
            now: clock,
            onExitToGuide: {})
    }
}
