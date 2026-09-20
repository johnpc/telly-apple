import Foundation

/// The wizard's step mutators — type choice, the draft field setters and the
/// BACK step machine — split out so ``AddPlaylistModel`` stays within its
/// source-line budget. BACK goes one step backwards; `false` means the caller
/// should leave the wizard entirely (mirrors the Android back semantics).
extension AddPlaylistModel {
    /// Routes the chooser to each source's entry step; Stalker stays inert.
    func chooseType(_ type: PlaylistType) {
        guard type != .stalkerPortal else { return }
        state.sourceType = type
        state.step = type == .xtreamCodes ? .xtreamEntry : .urlEntry
    }

    /// The entry step BACK returns to — Xtream credentials or the M3U URL.
    private var entryStep: WizardStep { state.sourceType == .xtreamCodes ? .xtreamEntry : .urlEntry }

    func setUrl(_ url: String) { state.url = url; state.error = nil }
    func setName(_ name: String) { state.name = name }
    func setEpgUrl(_ url: String) { state.epgUrl = url; state.error = nil }

    /// "Paste playlist URL" on the EPG step: copies the playlist URL to edit.
    func pastePlaylistUrl() { setEpgUrl(state.url.trimmed) }

    @discardableResult
    func back() -> Bool {
        switch state.step {
        case .urlEntry, .xtreamEntry: state.step = .typeChooser; state.error = nil
        case .processing: state.step = entryStep
        case .processed: parsed = nil; state.step = entryStep
        case .epgUrl: state.step = .processed; state.error = nil
        default: return false
        }
        return true
    }
}
