import Foundation

/// The user's "Buffer size" playback preference (Settings → Playback), ported
/// from the TiviMate-style Small/Medium/Large picker. Int-backed like
/// ``ResizeMode`` so the pick persists as a stable raw value (never reordered —
/// appended only); corrupt / out-of-range raws coerce to the default.
///
/// libVLC's stock `network-caching` is 1000 ms — a one-second cushion that any
/// provider jitter drains, causing the constant live-TV stutter (the bug this
/// setting fixes). Unlike ExoPlayer, libVLC 3 cannot decouple the start
/// threshold from the steady cushion: `network-caching` is both the pre-roll it
/// fills before playing AND the ahead-buffer it maintains, so tens-of-seconds
/// values would slow every zap by that long. Single-digit seconds is the
/// TiviMate-grade sweet spot: enough headroom to ride out multi-second provider
/// hiccups, small enough that channel zapping stays fast.
enum BufferSize: Int, CaseIterable, Identifiable {
    case small
    case medium
    case large

    var id: Int { rawValue }

    /// Milliseconds handed to `network-caching`. Small (3 s) trades headroom
    /// for the snappiest zap on pristine networks; Medium (6 s, the default)
    /// is six times the stock cushion and absorbs typical IPTV jitter; Large
    /// (12 s) rides out hostile provider stalls at the cost of zap latency.
    var cachingMs: Int {
        switch self {
        case .small: return 3_000
        case .medium: return 6_000
        case .large: return 12_000
        }
    }

    /// The picker row label, seconds spelled out so the latency cost is honest.
    var title: String {
        switch self {
        case .small: return "Small (3 s)"
        case .medium: return "Medium (6 s)"
        case .large: return "Large (12 s)"
        }
    }

    /// Unknown raws (corrupt store, forward-version backup) fall back to Medium.
    static func from(_ raw: Int) -> BufferSize { BufferSize(rawValue: raw) ?? .medium }
}

/// Pure mapping from the buffer preference to the exact per-media option
/// strings ``VLCKitPlayerEngine`` adds before `play()`. Kept minimal and
/// verified against the shipped VLCKit 3.6 binary: `network-caching` (the
/// cushion, the core fix) and `http-reconnect` (silently reopen the HTTP
/// connection on a provider hiccup instead of erroring out). `live-caching`
/// is deliberately absent — in libVLC 3 it applies only to capture-device
/// inputs (v4l2/dshow/screen), never http streams, which read
/// `network-caching`. Options apply to live, VOD and catch-up alike: every
/// stream is network-fetched, so all of them benefit from the same cushion.
enum BufferPolicy {
    /// The `VLCMedia.addOption` strings (canonical leading-colon form) for the
    /// given buffer preference, applied before the media starts playing.
    static func mediaOptions(for buffer: BufferSize) -> [String] {
        [":network-caching=\(buffer.cachingMs)", ":http-reconnect"]
    }
}
