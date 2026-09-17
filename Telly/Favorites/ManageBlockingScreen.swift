import SwiftUI

/// Bulk Manage-Blocking editor: every channel with a Block/Unblock toggle per
/// row that persists immediately. The Apple mirror of the Android BulkFlagSession
/// blocking screen, and the direct sibling of ``ManageVisibilityScreen``. When
/// the editor is PIN-locked (parental enforcement on + a PIN set) the shared
/// ``PinChallengeSheetView`` is shown instead of the list; a correct PIN unlocks
/// it. Pure presentation — logic lives in ``BlockingEditModel``.
struct ManageBlockingScreen: View {
    @State private var model: BlockingEditModel

    init(model: BlockingEditModel) { _model = State(initialValue: model) }

    var body: some View {
        Group {
            if model.locked {
                PinChallengeSheetView { model.unlock(pin: $0) }
            } else {
                List(model.channels, id: \.id) { channel in
                    HStack(spacing: 16) {
                        ChannelEditRowView(channel: channel)
                        Button(channel.flags.blocked ? "Unblock" : "Block") { model.toggleBlocked(channel) }
                            .buttonStyle(.borderless)
                    }
                }
            }
        }
        .navigationTitle("Manage Blocking")
        .task { model.load() }
    }
}
