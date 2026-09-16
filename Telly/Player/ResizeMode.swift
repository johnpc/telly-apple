import Foundation

/// The persisted "Resize mode" raw value (store-only key; captured TiviMate
/// default "Fit") mapped onto a surface resize mode. Unknown values fall back
/// to `.fit` — the previously hardcoded behavior. The VLC mapping of these
/// modes is deferred to the engine-adapter slice; this ports only the
/// string → enum logic from the Android `ResizeModes.of`.
enum ResizeMode {
    case fit
    case fill
    case zoom
    case fixedWidth
    case fixedHeight

    static func from(_ raw: String) -> ResizeMode {
        switch raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "stretch", "fill": return .fill
        case "crop", "zoom": return .zoom
        case "fixed width": return .fixedWidth
        case "fixed height": return .fixedHeight
        default: return .fit
        }
    }
}
