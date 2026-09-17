import SwiftUI

/// The VOD resume prompt (Apple mirror of Android's `VodResumePrompt`): a title
/// and two actions over the black stage — "Resume" continues from the stored
/// position, "Start over" restarts from the beginning. Pure presentation wired to
/// the model's ``VodPlaybackModel/resumeStored`` / ``VodPlaybackModel/startOver``
/// seams, so it stays coverage-exempt like the other playback `*View`s.
struct VodResumePromptView: View {
    let title: String
    let onResume: () -> Void
    let onStartOver: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            if !title.isEmpty {
                Text(title).font(.title2).bold().foregroundStyle(.white)
            }
            HStack(spacing: 20) {
                Button("Resume", action: onResume)
                    .buttonStyle(.borderedProminent)
                Button("Start over", action: onStartOver)
                    .buttonStyle(.bordered)
                    .foregroundStyle(.white)
            }
        }
        .padding(40)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}
