import Foundation

/// Builds the `playlistId → url` index ``PlaylistGroupFilter`` needs to resolve a
/// channel's owning playlist URL. `PlaylistEntity.id` is a nullable SQLite row
/// id while `ChannelEntity.playlistId` is a plain `Int`, so unsaved rows are
/// skipped and the key is narrowed to `Int`. Pure — mirrors the `Map<Long,String>`
/// Android derives from its playlist DAO before group-filtering.
enum PlaylistUrlIndex {
    static func build(_ playlists: [PlaylistEntity]) -> [Int: String] {
        var index: [Int: String] = [:]
        for playlist in playlists {
            guard let id = playlist.id else { continue }
            index[Int(id)] = playlist.url
        }
        return index
    }
}
