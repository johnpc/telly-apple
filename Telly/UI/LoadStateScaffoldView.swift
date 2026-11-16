import SwiftUI

/// Switches a data screen between its four `LoadPhase` states with one shared
/// vocabulary: a sweeping skeleton while loading, an error+Retry on failure, a
/// tailored `ContentUnavailableView` when a successful load is empty, and the
/// caller's real content once loaded. The phase change crossfades on the shared
/// `Motion.route` token (instant under Reduce Motion) so no state is a hard cut.
struct LoadStateScaffold<Content: View>: View {
    let phase: LoadPhase
    var emptyTitle: String
    var emptySystemImage: String
    var emptyMessage: String?
    let retry: () -> Void
    @ViewBuilder let content: () -> Content
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            switch phase {
            case .loading:
                SkeletonRowsView()
            case .failed:
                LoadFailureView(retry: retry)
            case .empty:
                ContentUnavailableView {
                    Label(emptyTitle, systemImage: emptySystemImage)
                } description: {
                    if let emptyMessage { Text(emptyMessage) }
                }
            case .loaded:
                content()
            }
        }
        .animation(Motion.gated(Motion.route, reduceMotion: reduceMotion), value: phase)
    }
}

/// The wording of a screen's empty state.
struct EmptyCopy {
    let title: String
    let systemImage: String
    let message: String?
}

/// ``LoadStateScaffold`` over any ``LoadableModel``: phase and Retry are wired
/// from the model exactly once, so screens only supply their empty-state copy.
struct LoadableScaffold<Model: LoadableModel, Content: View>: View {
    let model: Model
    let empty: EmptyCopy
    @ViewBuilder let content: () -> Content

    var body: some View {
        LoadStateScaffold(phase: model.phase, emptyTitle: empty.title, emptySystemImage: empty.systemImage,
                          emptyMessage: empty.message, retry: { Task { await model.retry() } }, content: content)
    }
}
