#if DEBUG
import SwiftUI

/// DEBUG-only screenshot route (`-tellyFeedbackProof`) for the action-feedback
/// work: it auto-fires the REAL "Update All Playlists" and "Clear playback
/// positions" actions on appear so the spinner + success/failure rows can be
/// captured without tap tooling (the `-tellyLoadState` idiom). Reuses the Slice-9
/// playlist fixtures; point a local http server at 127.0.0.1:8000 for the success
/// path, or leave it down to capture the update-failure row beside the clear
/// success — never touching the real provider.
extension ContentView {
    @ViewBuilder var feedbackProof: some View {
        if let playlistsModel {
            NavigationStack {
                Form {
                    Section("Playlists") {
                        UpdateActionButton(title: "Update All Playlists", autoRun: true) {
                            await playlistsModel.updateAll()
                        }
                    }
                    Section("Movies") {
                        UpdateActionButton(title: "Clear playback positions",
                                           busyTitle: "Clearing…", autoRun: true) {
                            env.clearVodPositions()
                        }
                    }
                }
                .navigationTitle("Feedback")
            }
        } else {
            Color.black.ignoresSafeArea().task { preparePlaylistsDebug() }
        }
    }
}
#endif
