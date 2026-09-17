import Foundation

/// The heart of the slice: channel attributes + programme window + "now" → a
/// playable catch-up URL. One tiny builder per catch-up type; nil when the type
/// cannot produce a URL for this channel (missing template / non-Xtream shape).
/// Ported 1:1 from Android `CatchupUrlBuilder` (CatchupUrlBuilder.kt:11-24).
enum CatchupUrlBuilder {
    static func build(streamUrl: String, attributes: CatchupAttributes,
                      startMs: Int, endMs: Int, nowMs: Int) -> String? {
        switch attributes.type {
        case .default:
            return attributes.source.map {
                CatchupTemplate.expand($0, startMs: startMs, endMs: endMs, nowMs: nowMs)
            }
        case .append:
            return attributes.source.map {
                streamUrl + CatchupTemplate.expand($0, startMs: startMs, endMs: endMs, nowMs: nowMs)
            }
        case .shift:
            return ShiftUrl.build(streamUrl: streamUrl, startMs: startMs, nowMs: nowMs)
        case .flussonic:
            return FlussonicUrl.build(streamUrl: streamUrl, startMs: startMs, endMs: endMs)
        case .xc:
            return XtreamUrl.build(streamUrl: streamUrl, startMs: startMs, endMs: endMs)
        }
    }
}
