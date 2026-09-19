import Foundation

extension ChannelRecord {
    /// Builds a persistence row from a domain channel (id 0 => nil, so SQLite
    /// autoincrements a fresh primary key on insert).
    init(_ e: ChannelEntity) {
        self.init(
            id: e.id == 0 ? nil : Int64(e.id),
            playlistId: Int64(e.playlistId),
            number: e.number,
            sortIndex: e.sortIndex,
            name: e.source.name,
            groupTitle: e.source.groupTitle,
            logoUrl: e.source.logoUrl,
            streamUrl: e.source.streamUrl,
            tvgId: e.source.tvgId,
            favorite: e.flags.favorite,
            hidden: e.flags.hidden,
            favoriteOrder: e.flags.favoriteOrder,
            catchupType: e.catchup.catchupType,
            catchupSource: e.catchup.catchupSource,
            catchupDays: e.catchup.catchupDays,
            customName: e.overrides.customName,
            audioDecoder: e.overrides.audioDecoder,
            videoDecoder: e.overrides.videoDecoder,
            epgOffsetMinutes: e.overrides.epgOffsetMinutes,
            externalPlayer: e.overrides.externalPlayer,
            epgOverride: e.overrides.epgOverride
        )
    }

    /// The domain channel this row represents.
    var entity: ChannelEntity {
        ChannelEntity(
            id: id.map(Int.init) ?? 0,
            playlistId: Int(playlistId),
            number: number,
            sortIndex: sortIndex,
            source: ChannelSource(name: name, groupTitle: groupTitle, logoUrl: logoUrl,
                                  streamUrl: streamUrl, tvgId: tvgId),
            flags: ChannelFlags(favorite: favorite, hidden: hidden,
                                favoriteOrder: favoriteOrder),
            catchup: ChannelCatchup(catchupType: catchupType, catchupSource: catchupSource,
                                    catchupDays: catchupDays),
            overrides: ChannelOverrides(customName: customName, audioDecoder: audioDecoder,
                                        videoDecoder: videoDecoder, epgOffsetMinutes: epgOffsetMinutes,
                                        externalPlayer: externalPlayer, epgOverride: epgOverride)
        )
    }
}
