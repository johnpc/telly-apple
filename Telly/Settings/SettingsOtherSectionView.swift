import SwiftUI

/// The "Other" settings group: a guarded "Reset All Settings" action that clears
/// every stored scalar preference back to its factory default via
/// ``SettingsStore/resetToDefaults()``. A confirmation dialog protects the
/// destructive reset. Search-history/Reminders/Recording/VOD have no Apple
/// implementation yet and are omitted rather than faked (plan §1.5).
struct SettingsOtherSectionView: View {
    let settings: SettingsStore
    @State private var confirming = false

    var body: some View {
        Section("Other") {
            Button("Reset All Settings", role: .destructive) { confirming = true }
        }
        .confirmationDialog("Reset all settings to defaults?",
                            isPresented: $confirming, titleVisibility: .visible) {
            Button("Reset", role: .destructive) { settings.resetToDefaults() }
            Button("Cancel", role: .cancel) {}
        }
    }
}
