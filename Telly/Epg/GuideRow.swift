import Foundation

/// One rendered channel row of the guide grid: the channel it belongs to, the
/// number shown in the channel column (`displayNumber`), and its contiguous
/// cell strip spanning the materialised window. `ChannelEntity`, `GuideCell`
/// and `Int` are all `Equatable`, so the conformance is synthesised. View-free
/// so row assembly stays unit-testable headlessly.
struct GuideRow: Equatable {
    let channel: ChannelEntity
    let displayNumber: Int
    let cells: [GuideCell]
}
