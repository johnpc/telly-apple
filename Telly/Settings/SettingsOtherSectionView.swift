import SwiftUI

/// The "Other" settings group: the "Save search history" toggle and a "Clear
/// search history" action (over the ``SearchHistory`` seam), plus a guarded
/// "Reset All Settings" that clears every stored scalar preference back to its
/// factory default via ``SettingsStore/resetToDefaults()``. Both destructive
/// actions confirm their result inline instead of returning silently — the reset
/// behind a confirmation dialog, the clear via the shared feedback button.
struct SettingsOtherSectionView: View {
    @Bindable var settings: SettingsStore
    @State private var confirming = false
    @State private var resetFeedback = UpdateFeedbackModel()

    var body: some View {
        Section("Other") {
            Toggle("Save Search History", isOn: $settings.saveSearchHistory)
            UpdateActionButton(title: "Clear Search History", busyTitle: "Clearing…") {
                SearchHistory(store: settings.backing,
                              saveEnabled: { settings.saveSearchHistory }).clear()
                return .success("Search history cleared")
            }
            Button("Reset All Settings", role: .destructive) { confirming = true }
                .disabled(resetFeedback.isRunning)
            UpdateStatusRow.forPhase(resetFeedback.phase, dismiss: resetFeedback.dismiss)
        }
        .confirmationDialog("Reset all settings to defaults?",
                            isPresented: $confirming, titleVisibility: .visible) {
            Button("Reset", role: .destructive) {
                Task { await resetFeedback.run { settings.resetToDefaults(); return .success("Settings reset") } }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}
