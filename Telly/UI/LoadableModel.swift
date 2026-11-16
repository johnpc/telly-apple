import Foundation
import Observation

/// THE load lifecycle every data screen shares (channel list, guide, Movies, My
/// List, History). Cached content renders at once — optionally with a silent
/// background refresh — while an empty store shows the skeleton until the refresh
/// resolves to loaded / empty / failed, and Retry re-runs that same refresh.
/// Conformers are the `@Observable` models themselves; `phase` is `nonmutating set`
/// (a class property) so the shared `start` / `retry` / `reload` here can assign it
/// without any `mutating` ceremony.
@MainActor
protocol LoadableModel: Observable {
    /// The screen's lifecycle, driving ``LoadStateScaffold``.
    var phase: LoadPhase { get nonmutating set }
    /// The (network) refresh awaited when the store is empty and on Retry.
    var refresh: () async throws -> Void { get }
    /// Whether a successful `start` with cached content also refreshes silently.
    var refreshesInBackground: Bool { get }
    /// Re-reads local state synchronously (never touches the network).
    func load()
    /// Whether there is something to show after `load()`.
    var hasContent: Bool { get }
}

extension LoadableModel {
    var refreshesInBackground: Bool { true }

    /// First appear: cached rows show immediately (refreshing silently if the
    /// conformer wants that); an empty store runs the skeleton → resolve drive.
    func start() async {
        load()
        if hasContent {
            phase = .loaded
            if refreshesInBackground {
                Task { phase = await refreshAndResolve(refresh: refresh, reload: load, hasContent: { hasContent }) }
            }
            return
        }
        await runLoad(setPhase: { phase = $0 }, refresh: refresh, reload: load, hasContent: { hasContent })
    }

    /// Retry from the empty / failed state: back to the skeleton, then re-resolve.
    func retry() async {
        await runLoad(setPhase: { phase = $0 }, refresh: refresh, reload: load, hasContent: { hasContent })
    }

    /// Re-read local state after a local mutation (a removal, a returned player)
    /// and re-resolve the phase without any refresh — so emptying a list lands on
    /// its empty state rather than a blank `loaded` list.
    func reload() {
        load()
        phase = LoadPhaseResolver.resolve(hasContent: hasContent, failed: false)
    }
}
