import Foundation

/// One row in the per-channel "Assign EPG" picker (the Apple port of Android
/// `AssignEpgSession`): either the "Auto (tvg-id)" option (`id == nil`) or a
/// concrete EPG channel id that has stored programme data. `selected` marks the
/// channel's current `overrides.epgOverride` choice.
struct AssignEpgOption: Equatable {
    let id: String?
    let title: String
    let summary: String?
    let selected: Bool
}

/// Pure builder + persist mapping for the Assign-EPG picker — ports
/// `AssignEpgSession.uiOf` and its `channel.copy(overrides:)` write, with no I/O.
enum AssignEpgOptions {
    /// The picker rows: "Auto (tvg-id)" first (summary = the channel's tvg-id,
    /// selected when no override is set), then every EPG id with stored data,
    /// each selected when it equals the channel's current override.
    static func rows(channel: ChannelEntity, epgIds: [String]) -> [AssignEpgOption] {
        let override = channel.overrides.epgOverride
        let auto = AssignEpgOption(id: nil, title: "Auto (tvg-id)",
                                   summary: channel.source.tvgId, selected: override == nil)
        return [auto] + epgIds.map {
            AssignEpgOption(id: $0, title: $0, summary: nil, selected: override == $0)
        }
    }

    /// The channel with its per-channel EPG override set to `override` (a nil
    /// override clears it back to Auto) — the value `ChannelStore.update` persists.
    static func applied(_ channel: ChannelEntity, override: String?) -> ChannelEntity {
        var updated = channel
        updated.overrides.epgOverride = override
        return updated
    }
}
