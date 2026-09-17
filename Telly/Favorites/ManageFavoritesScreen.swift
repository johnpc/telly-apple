import SwiftUI

/// Manage-Favorites / Reorder editor: each row shows the favourite star plus a
/// star toggle (Manage-Favorites mode) and up/down move controls. Explicit move
/// buttons work identically on tvOS (focus) and iPhone/iPad (tap). Pure
/// presentation — all logic lives in ``ChannelEditModel``.
struct ManageFavoritesScreen: View {
    @State private var model: ChannelEditModel

    init(model: ChannelEditModel) { _model = State(initialValue: model) }

    var body: some View {
        List(model.rows, id: \.id) { channel in
            HStack(spacing: 16) {
                ChannelEditRowView(channel: channel)
                if model.togglesFavorites {
                    Button { model.toggle(channel) } label: {
                        Image(systemName: channel.flags.favorite ? "star.slash" : "star")
                    }
                    .buttonStyle(.borderless)
                }
                Button { model.move(channel, delta: -1) } label: { Image(systemName: "chevron.up") }
                    .buttonStyle(.borderless)
                Button { model.move(channel, delta: 1) } label: { Image(systemName: "chevron.down") }
                    .buttonStyle(.borderless)
            }
        }
        .navigationTitle("Manage Favorites")
        .task { model.load() }
    }
}
