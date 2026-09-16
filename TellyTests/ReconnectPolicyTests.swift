import Testing
@testable import Telly

/// The live-stream reconnect backoff schedule and budget exhaustion.
struct ReconnectPolicyTests {
    @Test func backoffDoublesFromTheBaseDelay() {
        var policy = ReconnectPolicy(maxAttempts: 6, baseDelayMs: 1_000, maxDelayMs: 30_000)
        #expect(policy.nextDelayMs() == 1_000)
        #expect(policy.nextDelayMs() == 2_000)
        #expect(policy.nextDelayMs() == 4_000)
        #expect(policy.nextDelayMs() == 8_000)
    }

    @Test func delayIsCappedAtTheMaximum() {
        var policy = ReconnectPolicy(maxAttempts: 8, baseDelayMs: 1_000, maxDelayMs: 30_000)
        // 1s,2s,4s,8s,16s then the cap kicks in (32s -> 30s) and stays there.
        let delays = (0..<8).map { _ in policy.nextDelayMs() }
        #expect(delays == [1_000, 2_000, 4_000, 8_000, 16_000, 30_000, 30_000, 30_000])
    }

    @Test func budgetIsSpentAfterMaxAttempts() {
        var policy = ReconnectPolicy(maxAttempts: 2, baseDelayMs: 1_000, maxDelayMs: 30_000)
        #expect(policy.nextDelayMs() == 1_000)
        #expect(policy.nextDelayMs() == 2_000)
        #expect(policy.nextDelayMs() == nil)
        #expect(policy.nextDelayMs() == nil)
    }

    @Test func resetRestoresTheFullBudget() {
        var policy = ReconnectPolicy(maxAttempts: 3, baseDelayMs: 1_000, maxDelayMs: 30_000)
        _ = policy.nextDelayMs()
        _ = policy.nextDelayMs()
        policy.reset()
        #expect(policy.nextDelayMs() == 1_000)
        #expect(policy.nextDelayMs() == 2_000)
        #expect(policy.nextDelayMs() == 4_000)
        #expect(policy.nextDelayMs() == nil)
    }
}
