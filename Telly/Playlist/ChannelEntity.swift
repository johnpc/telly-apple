import Foundation

/// One channel row. `number` is the TiviMate-style sequential channel number
/// assigned from playlist order on import; `sortIndex` preserves that order
/// independently of future renumbering. `flags`/`overrides` survive refreshes.
struct ChannelEntity: Equatable {
    var id: Int = 0
    let playlistId: Int
    let number: Int
    let sortIndex: Int
    let source: ChannelSource
    var flags = ChannelFlags()
    var catchup = ChannelCatchup()
    var overrides = ChannelOverrides()

    /// What every channel-facing surface renders: the custom name when set.
    var displayName: String {
        if let custom = overrides.customName,
           !custom.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return custom
        }
        return source.name
    }

    /// The EPG channel id guide lookups use: the override, else the tvg-id.
    var epgId: String? { overrides.epgOverride ?? source.tvgId }
}
