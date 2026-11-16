#if DEBUG
import Foundation

/// `-tellyOverlay <name>`: WHICH live-player layer a screenshot proof pins open,
/// as one value instead of a Bool reader per layer — so the live demo switches
/// over it exhaustively and a typo in the argument is a nil, never a silent
/// no-op. Every helper is pure over its explicit `args` (the `DebugLaunch` idiom).
extension DebugLaunch {
    enum Overlay: String, CaseIterable {
        case zap, info, transport, quickBar, panel
        case multiview, multiviewMenu, multiviewPicker
        case trackAudio, trackSubtitles

        /// The track picker a `track…` overlay opens; nil for every other layer.
        var trackPicker: TrackPickerKind? {
            switch self {
            case .trackAudio: return .audio
            case .trackSubtitles: return .subtitles
            default: return nil
            }
        }
    }

    /// The overlay named by `-tellyOverlay`, or nil when absent / unknown.
    static func forcedOverlay(in args: [String]) -> Overlay? {
        value(for: "-tellyOverlay", in: args).flatMap(Overlay.init(rawValue:))
    }
}
#endif
