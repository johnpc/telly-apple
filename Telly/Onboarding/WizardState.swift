import Foundation

/// Wizard pages, in forward order (ported from the Android `WizardStep`).
enum WizardStep { case typeChooser, urlEntry, processing, processed, epgUrl, done }

/// Playlist source kinds offered by the type chooser. Only `m3u` is wired in
/// this slice; the Xtream/Stalker rows render disabled, matching the Android
/// chooser, until their loaders land.
enum PlaylistType: CaseIterable {
    case m3u, xtreamCodes, stalkerPortal

    var title: String {
        switch self {
        case .m3u: return "M3U playlist"
        case .xtreamCodes: return "Xtream Codes"
        case .stalkerPortal: return "Stalker Portal"
        }
    }

    var isAvailable: Bool { self == .m3u }
}

/// User-visible wizard failures; the UI maps them to display strings.
enum WizardError { case invalidURL, loadFailed }

/// Immutable snapshot of the add-playlist wizard.
struct WizardUiState: Equatable {
    var step: WizardStep = .typeChooser
    var url = ""
    var error: WizardError?
    var name = ""
    var liveCount = 0
    var movieCount = 0
    var groupCount = 0
    /// EPG step draft: pre-filled from the M3U's `url-tvg`.
    var epgUrl = ""

    var channelCount: Int { liveCount + movieCount }
}

extension String {
    /// Whitespace-and-newline-trimmed copy — the wizard trims every URL/name.
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
