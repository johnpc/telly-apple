import Foundation

/// Identifies the guide cell whose program info panel is open: the channel it
/// belongs to, the info-carrying cell, and its activation outcome (which action
/// the panel offers). `id` keys the `.sheet(item:)` presentation and matches the
/// old menu-target key so the DEBUG screenshot seed is unaffected.
struct GuideInfoTarget: Identifiable, Equatable {
    let channel: ChannelEntity
    let cell: GuideCell
    let selection: GuideSelection
    var id: String { "\(channel.id)|\(cell.startMs)" }
}
