import Foundation

/// The terminal result of a user-triggered "update" action, carrying a short,
/// non-technical message. Pure + `Equatable` so the feedback state machine and
/// its message wording are unit-testable without touching the network.
enum UpdateOutcome: Equatable {
    case success(String)
    case failure(String)
}

extension UpdateOutcome {
    /// "Update All Playlists" wording: a failure only when there was something
    /// to refresh yet nothing did; otherwise a channel-count confirmation.
    static func forAll(succeeded: Int, total: Int, channelCount: Int) -> UpdateOutcome {
        guard succeeded > 0 || total == 0 else { return .failure("Couldn’t update playlists") }
        return .success(channelsMessage(channelCount))
    }

    /// A single playlist's "Update Now" wording — its own channel count on
    /// success, a clear failure otherwise.
    static func forOne(succeeded: Bool, channelCount: Int) -> UpdateOutcome {
        succeeded ? .success(channelsMessage(channelCount)) : .failure("Couldn’t update playlist")
    }

    private static func channelsMessage(_ count: Int) -> String {
        count == 1 ? "Updated 1 channel" : "Updated \(count) channels"
    }

    /// A one-shot local action (clear/reset/export): its `success`/`failure`
    /// wording chosen by whether the underlying disk write threw.
    static func done(_ succeeded: Bool, success: String, failure: String) -> UpdateOutcome {
        succeeded ? .success(success) : .failure(failure)
    }
}

/// The four-state lifecycle a user-triggered update moves through: `idle` (no
/// chrome), `running` (spinner + disabled control), then a terminal
/// `success`/`failure` carrying the message to surface. Drives ``UpdateActionButton``.
enum UpdatePhase: Equatable {
    case idle
    case running
    case success(String)
    case failure(String)
}
