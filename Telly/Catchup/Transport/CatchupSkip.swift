import Foundation

/// The seek amounts, in milliseconds: `backMs` = the first configured skip step,
/// `forwardMs` = the second (the default preset's 10 s / 30 s reproduces the
/// reference's fixed catch-up steps). Ports the Android `CatchupSkip`
/// (`CatchupKeyPolicy.kt:39-50`). SkipSteps string parsing is deferred with
/// Settings; v1 bakes the default only.
struct CatchupSkip: Equatable, Sendable {
    let backMs: Int
    let forwardMs: Int

    static let defaults = CatchupSkip(backMs: 10_000, forwardMs: 30_000)

    /// Builds skip amounts from configured steps (seconds): back = the first
    /// step, forward = the second, each ×1000. Missing entries fall back to the
    /// defaults, mirroring Android's `CatchupSkip.of`.
    static func of(_ steps: [Int]) -> CatchupSkip {
        guard let back = steps.first else { return defaults }
        let forward = steps.count > 1 ? steps[1] : back
        return CatchupSkip(backMs: back * 1_000, forwardMs: forward * 1_000)
    }
}
