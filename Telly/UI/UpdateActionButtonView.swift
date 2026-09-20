import SwiftUI

/// A Settings action button that shows its own progress + result feedback: while
/// the injected async work runs it disables and relabels to "Updating…" with a
/// trailing spinner, and on completion it adds a dismissible success/failure row
/// beneath itself. Reused by every playlist/EPG "update" control so the feedback
/// reads as one system (its own `@State` state machine, ``UpdateFeedbackModel``).
struct UpdateActionButton: View {
    let title: String
    /// The label shown while the action runs (e.g. "Clearing…"); defaults to the
    /// update wording since most callers are refresh actions.
    var busyTitle = "Updating…"
    var isDisabled = false
    /// DEBUG screenshot hook: fires the action once on appear so the spinner +
    /// result states can be captured without tap tooling. Always false in the app.
    var autoRun = false
    let action: () async -> UpdateOutcome
    @State private var feedback = UpdateFeedbackModel()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            Button { Task { await feedback.run(action) } } label: { label }
                .disabled(isDisabled || feedback.isRunning)
            statusRow
        }
        .animation(Motion.gated(Motion.route, reduceMotion: reduceMotion), value: feedback.phase)
        .task { if autoRun { await feedback.run(action) } }
    }

    @ViewBuilder private var label: some View {
        if feedback.isRunning {
            HStack { Text(busyTitle); Spacer(); ProgressView() }
        } else {
            Text(title)
        }
    }

    @ViewBuilder private var statusRow: some View {
        UpdateStatusRow.forPhase(feedback.phase, dismiss: feedback.dismiss)
    }
}

/// The terminal-result row shown under ``UpdateActionButton``: a coloured icon +
/// message, tappable to dismiss (a real button so it also clears on tvOS focus).
struct UpdateStatusRow: View {
    let message: String
    let ok: Bool
    let dismiss: () -> Void

    var body: some View {
        Button(action: dismiss) {
            Label(message, systemImage: ok ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(ok ? Color.green : Color.red)
        }
        .buttonStyle(.plain)
        .accessibilityHint(Text("Dismiss"))
    }

    /// Renders the terminal-phase row (success/failure) or nothing while idle or
    /// running — the shared status treatment every "action" control reuses.
    @ViewBuilder
    static func forPhase(_ phase: UpdatePhase, dismiss: @escaping () -> Void) -> some View {
        switch phase {
        case .success(let message): UpdateStatusRow(message: message, ok: true, dismiss: dismiss)
        case .failure(let message): UpdateStatusRow(message: message, ok: false, dismiss: dismiss)
        default: EmptyView()
        }
    }
}
