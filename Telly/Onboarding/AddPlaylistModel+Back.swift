import Foundation

/// The wizard's step mutators — type choice, the draft field setters and the
/// BACK step machine — split out so ``AddPlaylistModel`` stays within its
/// source-line budget. BACK goes one step backwards; `false` means the caller
/// should leave the wizard entirely (mirrors the Android back semantics).
extension AddPlaylistModel {
    /// Only the M3U path exists in this slice; other types are inert.
    func chooseType(_ type: PlaylistType) {
        if type == .m3u { state.step = .urlEntry }
    }

    func setUrl(_ url: String) { state.url = url; state.error = nil }
    func setName(_ name: String) { state.name = name }
    func setEpgUrl(_ url: String) { state.epgUrl = url; state.error = nil }

    /// "Paste playlist URL" on the EPG step: copies the playlist URL to edit.
    func pastePlaylistUrl() { setEpgUrl(state.url.trimmed) }

    @discardableResult
    func back() -> Bool {
        switch state.step {
        case .urlEntry: state.step = .typeChooser; state.error = nil
        case .processing: state.step = .urlEntry
        case .processed: parsed = nil; state.step = .urlEntry
        case .epgUrl: state.step = .processed; state.error = nil
        default: return false
        }
        return true
    }
}
