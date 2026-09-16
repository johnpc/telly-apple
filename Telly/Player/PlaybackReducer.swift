import Foundation

/// The reconnect state machine, lifted out of the VLC adapter so it is fully
/// unit-testable without a live player (in Android this logic lived inside
/// `Media3PlayerEngine.onPlayerError`). The adapter feeds it lifecycle events
/// and performs the ``ErrorEffect`` it returns. `load`/`playing`/`stopped` all
/// reset the retry budget, so a stream that drops hours after a good connect
/// gets a full set of attempts again; each error consumes one attempt until the
/// budget is spent, at which point the failure is surfaced.
struct PlaybackReducer {
    /// What the adapter must do after a player error.
    enum ErrorEffect: Equatable {
        case reconnect(delayMs: Int)
        case fail
    }

    private(set) var state: PlayerState = .idle
    private var policy: ReconnectPolicy

    init(policy: ReconnectPolicy = ReconnectPolicy()) {
        self.policy = policy
    }

    mutating func onLoad() {
        policy.reset()
        state = .buffering
    }

    mutating func onBuffering() { state = .buffering }

    mutating func onPlaying() {
        policy.reset()
        state = .playing
    }

    mutating func onEnded() { state = .ended }

    mutating func onStopped() {
        policy.reset()
        state = .idle
    }

    mutating func onError(_ message: String) -> ErrorEffect {
        if let delay = policy.nextDelayMs() {
            state = .reconnecting
            return .reconnect(delayMs: delay)
        }
        state = .error(message)
        return .fail
    }
}
