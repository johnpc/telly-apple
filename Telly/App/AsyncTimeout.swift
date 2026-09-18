import Foundation

/// Thrown when an awaited operation outruns its deadline, so a stalled network
/// fetch resolves into the UI's error state instead of spinning forever.
struct TimeoutError: Error, Equatable {}

/// Races `operation` against a deadline: whichever finishes first wins, the
/// loser is cancelled. `sleep` is injected (defaults to the real clock) so tests
/// drive the timeout branch deterministically without waiting real seconds.
/// Used to bound the playlist/EPG fetches — see the wizard and the refresh seams.
func withTimeout<T: Sendable>(
    milliseconds: Int,
    sleep: @escaping @Sendable (UInt64) async throws -> Void = { try await Task.sleep(nanoseconds: $0) },
    _ operation: @escaping @Sendable () async throws -> T
) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask { try await operation() }
        group.addTask {
            try await sleep(UInt64(max(0, milliseconds)) * 1_000_000)
            throw TimeoutError()
        }
        defer { group.cancelAll() }
        guard let first = try await group.next() else { throw TimeoutError() }
        return first
    }
}
