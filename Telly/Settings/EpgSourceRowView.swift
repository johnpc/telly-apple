import SwiftUI

/// One editable custom-EPG-source row: a URL field pre-filled with the source's
/// current URL, a Save action that appears only once the field diverges (commits
/// via `onRename`), and a trash Remove action. Pure presentation — the edit draft
/// is local; committing and removing are the parent screen's closures.
struct EpgSourceRowView: View {
    let source: EpgSource
    let onRename: (String) -> Void
    let onRemove: () -> Void
    @State private var draft: String

    init(source: EpgSource, onRename: @escaping (String) -> Void, onRemove: @escaping () -> Void) {
        self.source = source
        self.onRename = onRename
        self.onRemove = onRemove
        _draft = State(initialValue: source.url)
    }

    var body: some View {
        HStack {
            TextField("https://…", text: $draft).textContentType(.URL)
            if draft.trimmed != source.url && !draft.trimmed.isEmpty {
                Button("Save") { onRename(draft.trimmed) }.buttonStyle(.borderless)
            }
            Button(role: .destructive, action: onRemove) {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
        }
    }
}
