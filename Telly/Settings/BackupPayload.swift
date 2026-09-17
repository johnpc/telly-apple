import Foundation

/// One playlist captured in a backup — by identity only (name/url/epgUrl). Its
/// channels are deliberately NOT serialised: a restore re-creates the playlist
/// empty and a later "Update playlist" re-fetches them, matching Android's
/// zero-channel re-add so a backup file stays small and never stale.
struct BackupPlaylist: Codable, Equatable {
    let name: String
    let url: String
    let epgUrl: String?
}

/// One custom EPG source in a backup, keyed to its playlist's stable URL so it
/// re-attaches after restore.
struct BackupEpgSource: Codable, Equatable {
    let playlistUrl: String
    let url: String
}

/// The serialisable shape of a settings/playlist backup — the Apple mirror of
/// Android's `BackupPayload`, extended with `epgSources` (custom EPG sources,
/// which the Android payload omitted). `version` guards forward-compat alongside
/// the tolerant decoder. Parental-lock state is never present here (see
/// ``SettingsSnapshot``).
struct BackupPayload: Codable, Equatable {
    var version = 1
    var settings: [String: String]
    var playlists: [BackupPlaylist]
    var epgSources: [BackupEpgSource] = []
}
