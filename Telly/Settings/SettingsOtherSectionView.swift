import SwiftUI

/// The "Other" settings group: the "Save search history" toggle and a "Clear
/// search history" action (over the ``SearchHistory`` seam), plus a guarded
/// "Reset All Settings" that clears every stored scalar preference back to its
/// factory default via ``SettingsStore/resetToDefaults()``. A confirmation
/// dialog protects the destructive reset.
struct SettingsOtherSectionView: View {
    @Bindable var settings: SettingsStore
    @State private var confirming = false

    var body: some View {
        Section("Other") {
            Toggle("Save Search History", isOn: $settings.saveSearchHistory)
            Button("Clear Search History") {
                SearchHistory(store: settings.backing,
                              saveEnabled: { settings.saveSearchHistory }).clear()
            }
            Button("Reset All Settings", role: .destructive) { confirming = true }
        }
        .confirmationDialog("Reset all settings to defaults?",
                            isPresented: $confirming, titleVisibility: .visible) {
            Button("Reset", role: .destructive) { settings.resetToDefaults() }
            Button("Cancel", role: .cancel) {}
        }
    }
}
