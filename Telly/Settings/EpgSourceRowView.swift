import SwiftUI

/// One editable custom-EPG-source row: a URL field pre-filled with the source's
/// current URL, a Save action that appears only once the field diverges (commits
/// via `onRename`, which reports whether the new URL was valid), a trash Remove
/// action, and an inline "invalid URL" line when a Save is rejected. Pure
/// presentation — the edit draft is local; committing and removing are closures.
struct EpgSourceRowView: View {
    let source: EpgSource
    let onRename: (String) -> Bool
    let onRemove: () -> Void
    @State private var draft: String
    @State private var invalid = false

    init(source: EpgSource, onRename: @escaping (String) -> Bool, onRemove: @escaping () -> Void) {
        self.source = source
        self.onRename = onRename
        self.onRemove = onRemove
        _draft = State(initialValue: source.url)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                TextField("https://…", text: $draft).textContentType(.URL)
                    .onChange(of: draft) { invalid = false }
                if draft.trimmed != source.url && !draft.trimmed.isEmpty {
                    Button("Save") { invalid = !onRename(draft.trimmed) }.buttonStyle(.borderless)
                }
                Button(role: .destructive, action: onRemove) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
            }
            if invalid {
                Text("Enter a valid http(s) URL").font(.footnote).foregroundStyle(.red)
            }
        }
    }
}
