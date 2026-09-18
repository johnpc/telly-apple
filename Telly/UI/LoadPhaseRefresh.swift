import Foundation

/// The shared reload step both data models drive from `start()`/`retry()`: run
/// the injected refresh, re-read local state, and resolve the terminal phase.
/// Extracted so the loop isn't copied per model (the duplication gate flags
/// copies); `@MainActor` because the model closures touch main-actor state.
@MainActor
func refreshAndResolve(
    refresh: () async throws -> Void,
    reload: () -> Void,
    hasContent: () -> Bool
) async -> LoadPhase {
    var failed = false
    do { try await refresh() } catch { failed = true }
    reload()
    return LoadPhaseResolver.resolve(hasContent: hasContent(), failed: failed)
}

/// The full skeleton→resolve drive shared by `start()` (empty path) and
/// `retry()`: flip to the skeleton, run the refresh, then publish the terminal
/// phase through the model's setter. One helper so neither the loop nor the
/// "show the skeleton first" step is copied per model.
@MainActor
func runLoad(
    setPhase: (LoadPhase) -> Void,
    refresh: () async throws -> Void,
    reload: () -> Void,
    hasContent: () -> Bool
) async {
    setPhase(.loading)
    setPhase(await refreshAndResolve(refresh: refresh, reload: reload, hasContent: hasContent))
}
