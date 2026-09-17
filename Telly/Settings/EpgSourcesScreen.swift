import SwiftUI

/// The per-playlist EPG-sources pane: the playlist's auto-detected `url-tvg`
/// shown as a read-only "(default)" row, then its custom sources (each editable
/// / removable via ``EpgSourceRowView``), then an add field. Pure presentation —
/// mutations delegate to ``PlaylistsSettingsModel``; the local `sources` mirror
/// is re-read after each change so the list refreshes without model-side state.
struct EpgSourcesScreen: View {
    @Bindable var model: PlaylistsSettingsModel
    let url: String
    @State private var sources: [EpgSource] = []
    @State private var draft = ""

    var body: some View {
        Form {
            if let auto = model.autoEpgUrl(for: url), !auto.isEmpty {
                Section("Automatic") { Text("\(EpgSource.host(auto)) (default)") }
            }
            Section("Custom Sources") {
                ForEach(sources, id: \.id) { source in
                    EpgSourceRowView(source: source,
                                     onRename: { rename(source.id, $0) },
                                     onRemove: { remove(source.id) })
                }
                HStack {
                    TextField("https://…", text: $draft).textContentType(.URL)
                    Button("Add") { add() }.disabled(draft.trimmed.isEmpty)
                }
            }
        }
        .navigationTitle("EPG Sources")
        .task { sources = model.sources(for: url) }
    }

    private func add() {
        if model.addSource(playlistUrl: url, url: draft.trimmed) { draft = "" }
        sources = model.sources(for: url)
    }

    private func rename(_ id: Int64, _ newUrl: String) {
        _ = model.setSourceUrl(id: id, url: newUrl)
        sources = model.sources(for: url)
    }

    private func remove(_ id: Int64) {
        model.removeSource(id: id)
        sources = model.sources(for: url)
    }
}
