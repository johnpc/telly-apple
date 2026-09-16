import Foundation

/// Pure label derivation for the picker rows and the quick-bar slots. Ported
/// from the Android `TrackLabels`.
enum TrackLabels {
    private static let stereoChannels = 2
    private static let bitsPerMegabit = 1_000_000.0
    private static let usLocale = Locale(identifier: "en_US")

    /// "1920×1080, 5.2 Mbps"; parts the container omits are dropped.
    static func video(_ t: VideoTrack) -> String {
        if t.width <= 0 || t.height <= 0 { return "Video" }
        let size = "\(t.width)×\(t.height)"
        if t.bitrate <= 0 { return size }
        let mbps = String(format: "%.1f Mbps", locale: usLocale, Double(t.bitrate) / bitsPerMegabit)
        return size + ", " + mbps
    }

    /// "English · Stereo"; undeclared languages fall back to "Audio N".
    static func audio(_ t: AudioTrack, index: Int) -> String {
        language(t.language, fallback: "Audio \(index + 1)") + channelsSuffix(t.channels)
    }

    /// "English"; undeclared languages fall back to "Subtitles N".
    static func text(_ t: TextTrack, index: Int) -> String {
        language(t.language, fallback: "Subtitles \(index + 1)")
    }

    /// The audio-sync slot/stepper label: "0 ms", "+150 ms", "-150 ms".
    static func sync(_ offsetMs: Int) -> String {
        offsetMs > 0 ? "+\(offsetMs) ms" : "\(offsetMs) ms"
    }

    /// The CC quick-bar slot: "Off" until a text track is enabled.
    static func subtitleSlot(_ s: TrackSnapshot) -> String {
        guard let index = s.texts.firstIndex(where: { $0.id == s.selectedTextId }) else { return "Off" }
        return text(s.texts[index], index: index)
    }

    private static func channelsSuffix(_ count: Int) -> String {
        switch count {
        case ..<1: return ""
        case 1: return " · Mono"
        case stereoChannels: return " · Stereo"
        default: return " · Surround"
        }
    }

    private static func language(_ code: String?, fallback: String) -> String {
        guard let code, !code.trimmingCharacters(in: .whitespaces).isEmpty, code != "und" else {
            return fallback
        }
        let display = usLocale.localizedString(forLanguageCode: code) ?? ""
        let name = display.isEmpty ? code : display
        return name.prefix(1).uppercased() + name.dropFirst()
    }
}
