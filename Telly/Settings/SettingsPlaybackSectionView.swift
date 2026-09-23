import SwiftUI

/// The "Playback" settings group: how long the on-screen overlay panels linger
/// before auto-hiding, and the stream buffer size (network cushion — see
/// ``BufferSize``). A buffer change applies on the next tune / engine mint,
/// never to an already-playing stream; the footer says so honestly.
struct SettingsPlaybackSectionView: View {
    @Bindable var settings: SettingsStore

    var body: some View {
        Section {
            Picker("Panels Timeout", selection: $settings.panelTimeoutSeconds) {
                ForEach(SettingsDefaults.panelTimeoutChoices, id: \.self) { seconds in
                    Text("\(seconds) s").tag(seconds)
                }
            }
            Picker("Buffer Size", selection: $settings.bufferSizeRaw) {
                ForEach(BufferSize.allCases) { size in
                    Text(size.title).tag(size.rawValue)
                }
            }
        } header: {
            Text("Playback")
        } footer: {
            Text("A larger buffer smooths out unstable streams; applies on the next channel change.")
        }
    }
}
