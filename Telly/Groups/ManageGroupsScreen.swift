import SwiftUI

/// Manage-Groups pane — the Apple port of Android's Create group + Group options.
/// A "New group" field creates an EMPTY custom group (Copy channels populates it
/// in a later slice), then the list of custom groups — each renamable and
/// deletable (with a destructive confirm) via ``ManageGroupRowView``. Pure
/// presentation — every mutation delegates to ``ManageGroupsModel``.
struct ManageGroupsScreen: View {
    @State private var model: ManageGroupsModel
    @State private var draft = ""
    @State private var deleting: CustomGroup?
    let makeCopyChannelsModel: () -> CopyChannelsModel

    init(model: ManageGroupsModel, makeCopyChannelsModel: @escaping () -> CopyChannelsModel) {
        _model = State(initialValue: model)
        self.makeCopyChannelsModel = makeCopyChannelsModel
    }

    var body: some View {
        Form {
            Section("New Group") {
                HStack {
                    TextField("Group name", text: $draft)
                    Button("Add") { add() }.disabled(draft.trimmed.isEmpty)
                }
            }
            Section {
                NavigationLink("Copy Channels") {
                    CopyChannelsScreen(model: makeCopyChannelsModel())
                }
            }
            Section("Custom Groups") {
                ForEach(model.groups) { group in
                    ManageGroupRowView(group: group,
                                       onRename: { model.rename(id: group.id, $0) },
                                       onDelete: { deleting = group })
                }
            }
        }
        .navigationTitle("Manage Groups")
        .task { model.load() }
        .confirmationDialog("Delete Group?", isPresented: deleteBinding, presenting: deleting) { group in
            Button("Delete", role: .destructive) { model.delete(id: group.id) }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func add() {
        model.create(draft)
        draft = ""
    }

    private var deleteBinding: Binding<Bool> {
        Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } })
    }
}
