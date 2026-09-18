import Foundation

/// The guide grid's load lifecycle, mirroring the channel list's: existing rows
/// render at once; an empty grid shows the skeleton, then resolves to loaded/
/// empty or, if its EPG refresh threw, the error+retry state. Kept out of the
/// core model so both files stay within the source-line budget.
extension GuideGridModel {
    /// First-appear load: materialise from the store, and when nothing is there
    /// await the refresh so an empty grid gets a skeleton, not a bare pane.
    func start() async {
        load()
        if !rows.isEmpty { phase = .loaded; return }
        await runLoad(setPhase: { phase = $0 }, refresh: refresh, reload: load, hasContent: has)
    }

    /// Retry from the failure/empty state: skeleton, then re-run the EPG refresh.
    func retry() async {
        await runLoad(setPhase: { phase = $0 }, refresh: refresh, reload: load, hasContent: has)
    }

    private func has() -> Bool { !rows.isEmpty }
}
