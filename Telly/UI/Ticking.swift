import Combine
import SwiftUI

/// THE clock for every screen whose model advances timed state (overlay auto-hide,
/// zap settle, position sampling, the guide's now-line): one coalesced main-run-loop
/// timer held for the view's lifetime, started once and cancelled on teardown. The
/// models stay pure deadline math over an injected `now`; this is the only place a
/// real timer lives, replacing per-screen `while !Task.isCancelled { sleep }` loops.
private struct TickingModifier: ViewModifier {
    let tick: () -> Void
    @State private var timer: Publishers.Autoconnect<Timer.TimerPublisher>

    init(every seconds: TimeInterval, tick: @escaping () -> Void) {
        self.tick = tick
        _timer = State(initialValue: Timer.publish(every: seconds, on: .main, in: .common).autoconnect())
    }

    func body(content: Content) -> some View {
        content.onReceive(timer) { _ in tick() }
    }
}

extension View {
    /// Calls `tick` every `seconds` while this view is on screen.
    func ticking(every seconds: TimeInterval, _ tick: @escaping () -> Void) -> some View {
        modifier(TickingModifier(every: seconds, tick: tick))
    }
}
