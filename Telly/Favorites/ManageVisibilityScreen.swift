import SwiftUI

/// Bulk Manage-Visibility editor: every channel (hidden included) with a
/// Hide/Show toggle per row. The Apple mirror of the Android BulkFlagSession
/// visibility screen. Pure presentation — logic lives in ``VisibilityEditModel``.
struct ManageVisibilityScreen: View {
    @State private var model: VisibilityEditModel

    init(model: VisibilityEditModel) { _model = State(initialValue: model) }

    var body: some View {
        List(model.channels, id: \.id) { channel in
            HStack(spacing: 16) {
                ChannelEditRowView(channel: channel)
                Button(channel.flags.hidden ? "Show" : "Hide") { model.toggleHidden(channel) }
                    .buttonStyle(.borderless)
            }
        }
        .navigationTitle("Manage Visibility")
        .task { model.load() }
    }
}
