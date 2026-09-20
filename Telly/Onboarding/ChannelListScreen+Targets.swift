import Foundation

/// The identity wrapper the row menu's "Assign EPG" action presents its sheet
/// over — the per-channel ``AssignEpgScreen`` target (mirrors ``LiveStageTarget``).
struct AssignEpgTarget: Identifiable {
    let channel: ChannelEntity
    var id: Int { channel.id }
}
