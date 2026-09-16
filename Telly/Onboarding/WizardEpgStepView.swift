import SwiftUI

/// The EPG-URL step: the M3U's `url-tvg` is pre-filled and editable; Done
/// persists the playlist. Blank skips the EPG; an invalid non-blank URL shows
/// the shared validation error.
struct WizardEpgStepView: View {
    let model: AddPlaylistModel

    private var epg: Binding<String> {
        Binding(get: { model.state.epgUrl }, set: { model.setEpgUrl($0) })
    }

    var body: some View {
        Form {
            Section {
                UrlFieldView(placeholder: "http://example.com/epg.xml", text: epg,
                             showInvalid: model.state.error == .invalidURL)
                Text("Optional — XMLTV only. Add or change it later in settings.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } header: {
                Text("EPG URL")
            }
            Button("Paste playlist URL") { model.pastePlaylistUrl() }
            Button("Done") { Task { await model.finishEpg() } }
        }
    }
}
