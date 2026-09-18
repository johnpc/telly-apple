import Foundation

/// The four-state lifecycle a data screen moves through, replacing the bare
/// `isLoading` bool so the channel list and guide can show a skeleton, an empty
/// message, or an error+retry instead of an indefinite spinner. `loaded` means
/// "render the content"; the other three own the screen.
enum LoadPhase: Equatable { case loading, loaded, empty, failed }

/// Pure terminal-phase resolver shared by every data model so the "did the load
/// leave us with something to show?" rule lives in exactly one place (the
/// duplication gate flags copies). Cached content always wins: a failed refresh
/// on top of existing rows stays `loaded` rather than blanking to an error.
enum LoadPhaseResolver {
    static func resolve(hasContent: Bool, failed: Bool) -> LoadPhase {
        if hasContent { return .loaded }
        return failed ? .failed : .empty
    }
}
