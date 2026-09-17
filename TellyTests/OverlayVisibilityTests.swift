import Testing
@testable import Telly

/// The clock-injected auto-hide state machine for transient overlays.
struct OverlayVisibilityTests {
    @Test func showAutoHidingRevealsThenExpiresAtDeadline() {
        var visibility = OverlayVisibility()
        visibility.showAutoHiding(.info, timeoutMs: 5_350, at: 0)
        #expect(visibility.resolve(at: 5_349) == .info)
        #expect(visibility.resolve(at: 5_350) == .none)
    }

    @Test func keepAliveExtendsTheDeadline() {
        var visibility = OverlayVisibility()
        visibility.showAutoHiding(.info, timeoutMs: 5_000, at: 0)
        visibility.keepAlive(at: 4_000)
        #expect(visibility.resolve(at: 5_000) == .info)
        #expect(visibility.resolve(at: 9_000) == .none)
    }

    @Test func keepAliveNoopsWhenNothingArmed() {
        var visibility = OverlayVisibility()
        visibility.set(.panel)
        visibility.keepAlive(at: 100)
        #expect(visibility.resolve(at: 10_000_000) == .panel)
    }

    @Test func setIsStickyAndCancelsPendingHide() {
        var visibility = OverlayVisibility()
        visibility.showAutoHiding(.info, timeoutMs: 5_000, at: 0)
        visibility.set(.panel)
        #expect(visibility.resolve(at: 10_000_000) == .panel)
    }

    @Test func keepAliveAfterExpiryDoesNotResurrect() {
        var visibility = OverlayVisibility()
        visibility.showAutoHiding(.info, timeoutMs: 5_000, at: 0)
        #expect(visibility.resolve(at: 6_000) == .none)
        visibility.keepAlive(at: 6_100)
        #expect(visibility.resolve(at: 10_000_000) == .none)
    }

    @Test func perOverlayDurationsComposeWithPanelTimeouts() {
        let timeouts = PanelTimeouts.default
        var zap = OverlayVisibility()
        zap.showAutoHiding(.zapInfo, timeoutMs: timeouts.zapMs, at: 0)
        #expect(zap.resolve(at: 5_100) == .zapInfo)
        #expect(zap.resolve(at: 5_500) == .none)

        var quickBar = OverlayVisibility()
        quickBar.showAutoHiding(.quickBar, timeoutMs: timeouts.quickBarMs, at: 0)
        #expect(quickBar.resolve(at: 5_000) == .none)
    }
}
