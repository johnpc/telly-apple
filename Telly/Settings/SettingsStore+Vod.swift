import Foundation

/// The Movies (VOD) playback preference. Mirrors the store's write-through idiom
/// (``SettingsStore/saveSearchHistory``): the getter returns the tracked raw var,
/// the setter updates it and persists through `backing`.
extension SettingsStore {
    /// Remember VOD playback positions for resume across launches (default: true).
    var vodRememberPosition: Bool {
        get { rawVodRememberPosition }
        set {
            rawVodRememberPosition = newValue
            backing.writeBool(newValue, SettingsKey.vodRememberPosition.rawValue)
        }
    }
}
