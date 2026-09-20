import SwiftUI

/// One playlist's detail pane: change its source URL, pick an auto-refresh
/// interval / update-on-start, refresh it now, reach its EPG-sources and
/// Manage-groups panes, and delete it. Pure presentation — every action is a
/// ``PlaylistsSettingsModel`` call; the interval/on-start controls bind through
/// custom get/set bindings since the settings are keyed per URL.
struct PlaylistDetailScreen: View {
    @Bindable var model: PlaylistsSettingsModel
    let url: String
    @State private var draftUrl = ""
    @State private var urlInvalid = false
    @State private var confirmingDelete = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("Source URL") {
                TextField("https://…", text: $draftUrl)
                    .textContentType(.URL)
                    .onChange(of: draftUrl) { urlInvalid = false }
                Button("Change URL") {
                    if model.changeUrl(old: url, new: draftUrl.trimmed) { dismiss() } else { urlInvalid = true }
                }
                .disabled(draftUrl.trimmed == url || draftUrl.trimmed.isEmpty)
                if urlInvalid {
                    Text("Enter a valid, unused http(s) URL").font(.footnote).foregroundStyle(.red)
                }
            }
            Section("Auto Update") {
                Picker("Refresh Every", selection: intervalBinding) {
                    ForEach(PlaylistSettingsKeys.PLAYLIST_INTERVAL_CHOICES, id: \.self) { hours in
                        Text(hours == 0 ? "Never" : "\(hours) h").tag(hours)
                    }
                }
                Toggle("Update On App Start", isOn: onStartBinding)
            }
            Section {
                UpdateActionButton(title: "Update Now") { await model.updateNow(url) }
                NavigationLink("EPG Sources") { EpgSourcesScreen(model: model, url: url) }
                NavigationLink("Manage Groups") { PlaylistGroupsScreen(model: model, url: url) }
            }
            Section {
                Button("Delete Playlist", role: .destructive) { confirmingDelete = true }
            }
        }
        .navigationTitle("Playlist")
        .onAppear { draftUrl = url }
        .confirmationDialog("Delete this playlist?", isPresented: $confirmingDelete,
                            titleVisibility: .visible) {
            Button("Delete Playlist", role: .destructive) { model.delete(url); dismiss() }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var intervalBinding: Binding<Int> {
        Binding(get: { model.interval(for: url) }, set: { model.setInterval(for: url, $0) })
    }

    private var onStartBinding: Binding<Bool> {
        Binding(get: { model.onStart(for: url) }, set: { model.setOnStart(for: url, $0) })
    }
}
