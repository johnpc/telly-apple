import SwiftUI

/// Entry screen for per-channel EPG assignment: every channel (a mirror of
/// ``ManageVisibilityScreen``), each a ``NavigationLink`` into its own
/// ``AssignEpgScreen`` picker. Surfaced from a Settings section so no capped
/// per-channel context menu has to grow. Pure presentation.
struct EpgAssignmentScreen: View {
    @State private var model: EpgAssignmentModel

    init(model: EpgAssignmentModel) { _model = State(initialValue: model) }

    var body: some View {
        List(model.channels, id: \.id) { channel in
            NavigationLink {
                AssignEpgScreen(model: model.assignModel(for: channel))
            } label: {
                ChannelEditRowView(channel: channel)
            }
        }
        .navigationTitle("EPG Assignment")
        .task { model.load() }
    }
}
