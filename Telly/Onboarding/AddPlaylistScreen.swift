import SwiftUI

/// The add-playlist wizard host: a `NavigationStack` whose content and title
/// follow `model.state.step`, with a leading Back/Cancel button driving the
/// model's one-step-back semantics. Reaching `.done` calls `onDone`.
struct AddPlaylistScreen: View {
    @State private var model: AddPlaylistModel
    let onDone: () -> Void

    init(model: AddPlaylistModel, onDone: @escaping () -> Void) {
        _model = State(initialValue: model)
        self.onDone = onDone
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(title)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(model.state.step == .typeChooser ? "Cancel" : "Back") {
                            if !model.back() { onDone() }
                        }
                    }
                }
        }
        .onChange(of: model.state.step) { _, step in
            if step == .done { onDone() }
        }
    }

    @ViewBuilder private var content: some View {
        switch model.state.step {
        case .typeChooser: WizardTypeStepView(model: model)
        case .urlEntry: WizardUrlStepView(model: model)
        case .processing: ProgressView("Loading playlist…")
        case .processed: WizardProcessedStepView(model: model)
        case .epgUrl: WizardEpgStepView(model: model)
        case .done: ProgressView()
        }
    }

    private var title: String {
        switch model.state.step {
        case .typeChooser: return "Add playlist"
        case .urlEntry: return "Playlist URL"
        case .processing: return "Loading"
        case .processed: return "Playlist ready"
        case .epgUrl: return "EPG URL"
        case .done: return ""
        }
    }
}
