import SwiftUI

/// The "Movies" settings group: a "Remember playback position" toggle gating VOD
/// resume, and a "Clear playback positions" action behind a confirmation dialog
/// (mirroring the destructive-confirm idiom of ``SettingsOtherSectionView``). On
/// confirm it invokes `onClear`, which empties the `vod_positions` store.
struct SettingsVodSectionView: View {
    @Bindable var settings: SettingsStore
    let onClear: () -> Void
    @State private var confirming = false

    var body: some View {
        Section("Movies") {
            Toggle("Remember playback position", isOn: $settings.vodRememberPosition)
            Button("Clear playback positions", role: .destructive) { confirming = true }
        }
        .confirmationDialog("Clear all saved playback positions?",
                            isPresented: $confirming, titleVisibility: .visible) {
            Button("Clear", role: .destructive, action: onClear)
            Button("Cancel", role: .cancel) {}
        }
    }
}
