import Foundation

/// TiviMate's playlist classification (device-verified, ported from Android):
/// entries whose stream URL carries a video-file extension are VOD "Movies";
/// streams (.ts/.m3u8/no extension) are live channels. One source of truth —
/// the wizard summary and the importer both dispatch on `isVod`.
enum VodClassifier {
    private static let vodExtensions: Set<String> = ["mp4", "mkv", "avi", "mov"]

    static func isVod(_ streamUrl: String) -> Bool {
        let beforeQuery = streamUrl.split(separator: "?", maxSplits: 1)[0]
        guard let dot = beforeQuery.lastIndex(of: ".") else { return false }
        let ext = beforeQuery[beforeQuery.index(after: dot)...].lowercased()
        return vodExtensions.contains(ext)
    }

    /// Refresh-stable resume identity for a movie — deliberately `streamUrl|name`
    /// (NOT `ChannelImporter.keyOf`): VOD entries rarely carry a meaningful
    /// tvg-id, so a tvg-id-first key would collide and lose stored positions.
    static func itemKey(streamUrl: String, name: String) -> String {
        "\(streamUrl)|\(name)"
    }
}
