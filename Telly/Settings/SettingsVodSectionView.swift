import SwiftUI

/// The "Movies" settings group: a "Remember playback position" toggle gating VOD
/// resume, and a "Clear playback positions" action behind a confirmation dialog
/// (mirroring the destructive-confirm idiom of ``SettingsOtherSectionView``). On
/// confirm it runs `onClear` through a feedback state machine so the result is
/// confirmed with a success/failure row (``UpdateStatusRow``) rather than silently.
struct SettingsVodSectionView: View {
    @Bindable var settings: SettingsStore
    let onClear: () -> UpdateOutcome
    @State private var confirming = false
    @State private var feedback = UpdateFeedbackModel()

    var body: some View {
        Section("Movies") {
            Toggle("Remember playback position", isOn: $settings.vodRememberPosition)
            Button("Clear playback positions", role: .destructive) { confirming = true }
                .disabled(feedback.isRunning)
            UpdateStatusRow.forPhase(feedback.phase, dismiss: feedback.dismiss)
        }
        .confirmationDialog("Clear all saved playback positions?",
                            isPresented: $confirming, titleVisibility: .visible) {
            Button("Clear", role: .destructive) { Task { await feedback.run { onClear() } } }
            Button("Cancel", role: .cancel) {}
        }
    }
}
