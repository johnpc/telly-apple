#if DEBUG
import Foundation

extension DebugLaunch {
    /// The channel-list group to preselect for the screenshot proof
    /// (`-tellyChannelGroup Favorites`), or nil.
    static func forcedChannelGroup(in args: [String]) -> String? {
        value(for: "-tellyChannelGroup", in: args)
    }

    /// Flags the first two visible channels favourite so the Favorites filter
    /// and the star indicator render populated — set by `-tellySeedFavorite`.
    /// Idempotent (skips channels already favourite); a no-op without the flag.
    static func seedFavoritesIfRequested(into store: ChannelStore, args: [String]) {
        guard args.contains("-tellySeedFavorite") else { return }
        let channels = (try? store.visibleChannels()) ?? []
        for channel in channels.prefix(2) where !channel.flags.favorite {
            try? store.update(ChannelReorder.toggled(channels, channel))
        }
    }
}
#endif
