import SwiftUI

/// The "Playlist is processed" step: an editable name plus the live/movie/group
/// counts, then Next to the EPG step.
struct WizardProcessedStepView: View {
    let model: AddPlaylistModel

    private var name: Binding<String> {
        Binding(get: { model.state.name }, set: { model.setName($0) })
    }

    var body: some View {
        Form {
            Section("Playlist name") {
                TextField("Playlist name", text: name)
            }
            Section("Playlist is processed") {
                LabeledContent("Channels", value: "\(model.state.channelCount)")
                LabeledContent("Movies", value: "\(model.state.movieCount)")
                LabeledContent("Groups", value: "\(model.state.groupCount)")
            }
            Button("Next") { model.confirm() }
        }
    }
}
