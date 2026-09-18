import Testing
import Foundation
@testable import Telly

/// `withTimeout`: the operation's value wins when it finishes first, its error
/// propagates, and a stalled operation resolves to `TimeoutError` — the sleep
/// seam is injected so the timeout branch is deterministic (no real waiting).
struct AsyncTimeoutTests {
    struct Boom: Error {}

    @Test func returnsOperationValueWhenItFinishesFirst() async throws {
        let value = try await withTimeout(milliseconds: 1_000) { 7 }
        #expect(value == 7)
    }

    @Test func propagatesOperationError() async {
        await #expect(throws: Boom.self) {
            try await withTimeout(milliseconds: 1_000) { throw Boom() }
        }
    }

    @Test func stalledOperationTimesOut() async {
        await #expect(throws: TimeoutError.self) {
            // sleep fires immediately → the deadline wins; the operation never returns.
            try await withTimeout(milliseconds: 5, sleep: { _ in }) {
                try await Task.sleep(nanoseconds: 5_000_000_000)
                return 0
            }
        }
    }
}
