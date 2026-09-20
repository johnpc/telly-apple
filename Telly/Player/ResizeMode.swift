import Foundation

/// The persisted "Resize mode" (aspect-ratio / zoom) player control, ported from
/// the Android `ResizeModes.of` string parser and now `Int`-backed so a selected
/// mode persists as a stable raw value (never reordered — appended only). `.fit`
/// is the TiviMate default; unknown store strings fall back to it. The engine
/// mapping (VLC aspect / crop / stretch) lives in `ResizeMode+Vlc`; the picker
/// rows and titles in `ResizeMode+Menu`.
enum ResizeMode: Int, CaseIterable {
    case fit
    case fill
    case zoom
    case fixedWidth
    case fixedHeight
    case ratio16x9
    case ratio4x3

    static func from(_ raw: String) -> ResizeMode {
        switch raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "stretch", "fill": return .fill
        case "crop", "zoom": return .zoom
        case "fixed width": return .fixedWidth
        case "fixed height": return .fixedHeight
        case "16:9": return .ratio16x9
        case "4:3": return .ratio4x3
        default: return .fit
        }
    }
}
