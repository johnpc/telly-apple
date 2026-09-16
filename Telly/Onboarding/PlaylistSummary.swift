import Foundation

/// Pure helpers behind the "Playlist is processed" wizard step. TiviMate
/// classifies `.mp4`/`.mkv` stream URLs as VOD ("Movies") and everything else
/// as live channels, and suggests the source URL's host as the playlist name.
enum PlaylistSummary {
    static func movieCount(_ channels: [M3uChannel]) -> Int {
        channels.filter { VodClassifier.isVod($0.streamURL) }.count
    }

    static func liveCount(_ channels: [M3uChannel]) -> Int {
        channels.count - movieCount(channels)
    }

    /// Distinct non-blank `group-title` values, as shown on the stub screen.
    static func groupCount(_ channels: [M3uChannel]) -> Int {
        var seen: Set<String> = []
        for channel in channels {
            let group = channel.groupTitle?.trimmingCharacters(in: .whitespaces)
            if let group, !group.isEmpty { seen.insert(group) }
        }
        return seen.count
    }

    /// TiviMate pre-fills the playlist name with the URL's host.
    static func suggestName(_ sourceUrl: String) -> String {
        HttpUrl.host(sourceUrl) ?? sourceUrl
    }
}
