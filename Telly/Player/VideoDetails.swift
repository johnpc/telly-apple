import Foundation

/// The decoded stream's video/audio shape, surfaced to the info overlay and the
/// quick-bar badges. Built by the engine adapter once the first frame's format
/// is known; `nil` until then. `frameRate` is 0 when the container omits it (TS
/// often does — the adapter estimates it from frame timings). Ported from the
/// Android `VideoDetails`.
struct VideoDetails: Equatable {
    let width: Int
    let height: Int
    let frameRate: Double
    let audioChannels: Int
}
