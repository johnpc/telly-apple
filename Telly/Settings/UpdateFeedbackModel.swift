import Foundation

/// The pure async state machine behind every "update" control: `idle` →
/// `running` → `success`/`failure`. The work is injected as a closure returning
/// an ``UpdateOutcome``, so the transitions are unit-testable with a fake updater
/// and never touch the network. Views own an instance as `@State`; the button
/// disables + spins while ``isRunning`` and shows the terminal message after.
@MainActor
@Observable
final class UpdateFeedbackModel {
    private(set) var phase: UpdatePhase = .idle

    var isRunning: Bool { phase == .running }

    /// Flips to `running`, awaits the injected work, then lands on the terminal
    /// phase carrying its message. Re-running from a terminal phase clears it.
    func run(_ operation: () async -> UpdateOutcome) async {
        phase = .running
        switch await operation() {
        case .success(let message): phase = .success(message)
        case .failure(let message): phase = .failure(message)
        }
    }

    /// Dismisses a terminal message back to `idle` (the status row's tap target).
    func dismiss() { phase = .idle }
}
