import Foundation

/// Where VOD playback is: loading the item, the resume prompt (carrying the
/// stored position to seek to), or playing. Mirrors the Android `VodStage`.
enum VodStage: Equatable {
    case loading
    case resumePrompt(positionMs: Int)
    case playing
}

/// The transport's clock sample: current position and known duration. `permille`
/// is the clamped [0, 1000] progress the bar renders (0 while duration unknown).
struct VodProgress: Equatable {
    let positionMs: Int
    let durationMs: Int

    var permille: Int {
        guard durationMs > 0 else { return 0 }
        return min(1000, max(0, positionMs * 1000 / durationMs))
    }
}
