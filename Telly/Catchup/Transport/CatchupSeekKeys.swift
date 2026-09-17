import Foundation

/// Which seek keys the Remote-control settings currently enable. Ports the
/// Android `CatchupSeekKeys` (`CatchupKeyPolicy.kt:25-32`).
struct CatchupSeekKeys: Equatable, Sendable {
    let rwFf: Bool
    let leftRight: Bool
    let downUp: Bool
    let rwLive: Bool
    let leftLive: Bool
    let downLive: Bool

    /// Apple's baked v1 defaults. Android defaults only `rwFf=true` because it
    /// has discrete RW/FF hardware; the Siri Remote does not, so Apple also
    /// bakes `leftRight=true` for D-pad seek (transport plan deviation 2).
    static let appleDefaults = CatchupSeekKeys(
        rwFf: true,
        leftRight: true,
        downUp: false,
        rwLive: false,
        leftLive: false,
        downLive: false
    )
}
