import SwiftUI

/// One custom-group row in ``ManageGroupsScreen``: a name field pre-filled with
/// the group's current name, a Rename action that appears only once the field
/// diverges (commits via `onRename`), and a destructive Delete action. Pure
/// presentation mirroring ``EpgSourceRowView`` — the edit draft is local, so the
/// inline field works across iOS/iPadOS/tvOS (no alert-embedded text field).
struct ManageGroupRowView: View {
    let group: CustomGroup
    let onRename: (String) -> Void
    let onDelete: () -> Void
    @State private var draft: String

    init(group: CustomGroup, onRename: @escaping (String) -> Void, onDelete: @escaping () -> Void) {
        self.group = group
        self.onRename = onRename
        self.onDelete = onDelete
        _draft = State(initialValue: group.name)
    }

    var body: some View {
        HStack {
            TextField("Group name", text: $draft)
            if draft.trimmed != group.name && !draft.trimmed.isEmpty {
                Button("Rename") { onRename(draft.trimmed) }.buttonStyle(.borderless)
            }
            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
        }
    }
}
