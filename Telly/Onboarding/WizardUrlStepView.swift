import SwiftUI

/// The playlist-URL entry step: an http(s) field plus Next, showing either the
/// invalid-URL or the load-failed message from the model.
struct WizardUrlStepView: View {
    let model: AddPlaylistModel

    private var url: Binding<String> {
        Binding(get: { model.state.url }, set: { model.setUrl($0) })
    }

    var body: some View {
        Form {
            Section {
                UrlFieldView(placeholder: "http://example.com/playlist.m3u", text: url,
                             showInvalid: model.state.error == .invalidURL)
                if model.state.error == .loadFailed {
                    Text("Could not load the playlist. Check the URL and try again.")
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            } header: {
                Text("Enter your M3U playlist URL")
            }
            Button("Next") { Task { await model.submitUrl() } }
                .disabled(model.state.url.trimmed.isEmpty)
        }
    }
}
