import Foundation

/// How a provider exposes already-aired programmes (community M3U values).
/// Ported 1:1 from Android `CatchupType` (CatchupAttributes.kt:6-27).
enum CatchupType: Equatable {
    case `default`
    case append
    case shift
    case flussonic
    case xc

    /// Shift/flussonic/xc rewrite the live URL, so they need no template.
    var rewritesLiveUrl: Bool { self != .default && self != .append }

    /// Maps a raw `catchup` / `catchup-type` value (trimmed, lowercased) to a
    /// known type; unrecognised or absent values yield nil.
    static func of(_ raw: String?) -> CatchupType? {
        switch raw?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "default": return .default
        case "append": return .append
        case "shift": return .shift
        case "flussonic": return .flussonic
        case "xc": return .xc
        default: return nil
        }
    }
}
