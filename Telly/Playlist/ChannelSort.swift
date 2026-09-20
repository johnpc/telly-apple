import Foundation

/// The user-selectable channel-list ordering, applied identically by the channel
/// list, the in-playback panel and the guide rows. `.default` is TiviMate's
/// playlist/channel-number order (the incoming array, preserved); `.nameAZ`
/// sorts by display name. `Int`-backed so a choice persists as a stable raw
/// value (never reordered — appended only); unknown stored raws coerce to
/// `.default`. Android telly ships no channel-sort control (channels are always
/// number-ordered), so only these two faithful modes are offered — there is no
/// tvg-chno field to key a distinct "Number" mode on (`number` == default order).
enum ChannelSort: Int, CaseIterable, Identifiable {
    case `default`
    case nameAZ

    var id: Int { rawValue }

    /// The picker label for this mode.
    var title: String {
        switch self {
        case .default: return "Default"
        case .nameAZ: return "Name (A–Z)"
        }
    }

    /// Coerces a stored raw value into a mode, defaulting to `.default`.
    static func from(_ raw: Int) -> ChannelSort { ChannelSort(rawValue: raw) ?? .default }

    /// Orders `channels` by this mode. `.default` preserves the incoming
    /// (playlist/number) order; `.nameAZ` sorts case-insensitively by display
    /// name, ties broken by the original position so the result is deterministic
    /// and equal names never reshuffle relative to the default order.
    func sorted(_ channels: [ChannelEntity]) -> [ChannelEntity] {
        guard self == .nameAZ else { return channels }
        return channels.enumerated().sorted { lhs, rhs in
            let order = lhs.element.displayName.localizedCaseInsensitiveCompare(rhs.element.displayName)
            return order == .orderedSame ? lhs.offset < rhs.offset : order == .orderedAscending
        }.map(\.element)
    }
}
