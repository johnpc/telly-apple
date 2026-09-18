import Foundation

/// The channel list's load lifecycle, kept out of the core model so both files
/// stay within the source-line budget. Cached channels render immediately (with
/// a silent background refresh); only an empty store shows the skeleton and,
/// should its refresh throw, the error+retry state (never blanking real rows).
extension ChannelListModel {
    /// First-appear load: shows cached channels at once, otherwise awaits the
    /// refresh and resolves to loaded/empty/failed so an empty store gets a
    /// skeleton rather than a bare, seemingly-hung list.
    func start() async {
        load()
        if !channels.isEmpty {
            phase = .loaded
            Task { phase = await refreshAndResolve(refresh: refresh, reload: load, hasContent: has) }
            return
        }
        await runLoad(setPhase: { phase = $0 }, refresh: refresh, reload: load, hasContent: has)
    }

    /// Retry from the failure/empty state: back to the skeleton, then re-run the
    /// injected refresh and re-resolve.
    func retry() async {
        await runLoad(setPhase: { phase = $0 }, refresh: refresh, reload: load, hasContent: has)
    }

    private func has() -> Bool { !channels.isEmpty }
}
