import SwiftUI

/// The "Playlists" settings group: one navigation row per stored playlist (into
/// its detail pane), an Add button that presents the shared add-playlist wizard,
/// and an "Update all" action. Pure presentation — the list, add and update
/// logic all live in ``PlaylistsSettingsModel`` (the wizard is the existing
/// ``AddPlaylistModel``, reused here rather than re-implemented).
struct SettingsPlaylistsSectionView: View {
    @Bindable var model: PlaylistsSettingsModel
    @State private var addingPlaylist = false

    var body: some View {
        Section("Playlists") {
            ForEach(model.playlists, id: \.url) { playlist in
                NavigationLink(playlist.name) {
                    PlaylistDetailScreen(model: model, url: playlist.url)
                }
            }
            Button("Add Playlist") { addingPlaylist = true }
            UpdateActionButton(title: "Update All Playlists",
                               isDisabled: model.playlists.isEmpty) { await model.updateAll() }
        }
        .task { model.load() }
        .sheet(isPresented: $addingPlaylist) {
            AddPlaylistScreen(model: model.makeAddModel()) {
                addingPlaylist = false
                model.load()
                model.reload()  // republish + write-through the new playlist config
            }
        }
    }
}
