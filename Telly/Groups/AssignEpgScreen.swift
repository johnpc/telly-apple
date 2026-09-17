import SwiftUI

/// The per-channel "Assign EPG" picker: a list of ``AssignEpgOption`` rows —
/// "Auto (tvg-id)" first, then every EPG id with stored programme data — with a
/// checkmark on the selected row. Tapping a row persists that override via
/// ``AssignEpgModel``. Pure presentation.
struct AssignEpgScreen: View {
    @State private var model: AssignEpgModel

    init(model: AssignEpgModel) { _model = State(initialValue: model) }

    var body: some View {
        List(model.rows, id: \.id) { row in
            Button { model.select(row.id) } label: {
                HStack {
                    VStack(alignment: .leading) {
                        Text(row.title)
                        if let summary = row.summary, !summary.isEmpty {
                            Text(summary).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    Spacer(minLength: 0)
                    if row.selected { Image(systemName: "checkmark") }
                }
            }
            .buttonStyle(.plain)
        }
        .navigationTitle("Assign EPG")
        .task { model.load() }
    }
}
