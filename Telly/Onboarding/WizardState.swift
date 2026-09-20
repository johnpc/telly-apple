import Foundation

/// Wizard pages, in forward order (ported from the Android `WizardStep`).
enum WizardStep { case typeChooser, urlEntry, xtreamEntry, processing, processed, epgUrl, done }

/// Playlist source kinds offered by the type chooser. M3U and Xtream Codes are
/// wired; the Stalker Portal row stays disabled (out of scope for this slice),
/// matching the Android chooser until its loader lands.
enum PlaylistType: CaseIterable {
    case m3u, xtreamCodes, stalkerPortal

    var title: String {
        switch self {
        case .m3u: return "M3U playlist"
        case .xtreamCodes: return "Xtream Codes"
        case .stalkerPortal: return "Stalker Portal"
        }
    }

    var isAvailable: Bool { self == .m3u || self == .xtreamCodes }
}

/// User-visible wizard failures; the UI maps them to display strings.
enum WizardError { case invalidURL, loadFailed, authFailed }

/// Immutable snapshot of the add-playlist wizard.
struct WizardUiState: Equatable {
    var step: WizardStep = .typeChooser
    /// The chosen source kind — drives back navigation and the processing title.
    var sourceType: PlaylistType = .m3u
    var url = ""
    var error: WizardError?
    var name = ""
    var liveCount = 0
    var movieCount = 0
    var groupCount = 0
    /// EPG step draft: pre-filled from the M3U's `url-tvg` (or Xtream `xmltv.php`).
    var epgUrl = ""
    /// Xtream step drafts: the server (host[:port], optional scheme) + credentials.
    var server = ""
    var username = ""
    var password = ""

    var channelCount: Int { liveCount + movieCount }
}

extension String {
    /// Whitespace-and-newline-trimmed copy — the wizard trims every URL/name.
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }

    /// This string trimmed, or nil when it is empty/whitespace — used to drop
    /// blank Xtream fields (`epg_channel_id`, `stream_icon`, …) to nil.
    var nonBlank: String? { trimmed.isEmpty ? nil : trimmed }
}
