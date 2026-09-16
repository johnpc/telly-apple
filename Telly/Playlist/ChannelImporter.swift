import Foundation

/// Turns parsed M3U channels into channel rows. Channel numbers are assigned
/// sequentially from playlist order (TiviMate default). User flags and the
/// Channel-options overrides survive refreshes via `identityOf`: a channel is
/// "the same" when its tvg-id matches, falling back to stream URL + name.
enum ChannelImporter {
    /// Stable identity used to carry user flags across playlist refreshes.
    static func identityOf(tvgId: String?, streamUrl: String, name: String) -> String {
        if let id = tvgId, !id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return id }
        return "\(streamUrl)|\(name)"
    }

    /// `identityOf` for a stored row — custom-group membership keys use it.
    static func keyOf(_ channel: ChannelEntity) -> String {
        identityOf(tvgId: channel.source.tvgId, streamUrl: channel.source.streamUrl,
                   name: channel.source.name)
    }

    /// Builds the replacement rows for `playlistId` from a fresh parse.
    static func importChannels(playlistId: Int, parsed: [M3uChannel],
                               previous: [ChannelEntity]) -> [ChannelEntity] {
        let carried = Dictionary(previous.map { (keyOf($0), $0) }, uniquingKeysWith: { _, last in last })
        return parsed.enumerated().map {
            row(playlistId: playlistId, index: $0.offset, channel: $0.element, carried: carried)
        }
    }

    private static func row(playlistId: Int, index: Int, channel: M3uChannel,
                            carried: [String: ChannelEntity]) -> ChannelEntity {
        let key = identityOf(tvgId: channel.tvgID, streamUrl: channel.streamURL, name: channel.title)
        let source = ChannelSource(name: channel.title, groupTitle: channel.groupTitle,
                                   logoUrl: channel.tvgLogo, streamUrl: channel.streamURL,
                                   tvgId: channel.tvgID)
        let catchup = ChannelCatchup(catchupType: channel.catchup, catchupSource: channel.catchupSource,
                                     catchupDays: channel.catchupDays)
        return ChannelEntity(playlistId: playlistId, number: index + 1, sortIndex: index,
                             source: source, flags: carried[key]?.flags ?? ChannelFlags(),
                             catchup: catchup, overrides: carried[key]?.overrides ?? ChannelOverrides())
    }
}
