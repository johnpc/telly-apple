import Foundation

/// The search screen's persisted preferences. Mirrors the store's write-through
/// idiom: get returns the tracked raw var, set updates it and persists through
/// `backing`.
extension SettingsStore {
    /// Persist committed search queries for the search screen (default: true).
    var saveSearchHistory: Bool {
        get { rawSaveSearchHistory }
        set {
            rawSaveSearchHistory = newValue
            backing.writeBool(newValue, SettingsKey.saveSearchHistory.rawValue)
        }
    }
}
