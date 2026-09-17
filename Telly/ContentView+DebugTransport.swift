#if DEBUG
import SwiftUI

/// DEBUG-only catch-up TRANSPORT screenshot route (`-tellyCatchupTransport`),
/// split from `+DebugCatchup` to keep both files lean. Reuses `prepareCatchupDemo`
/// to seed the aired-programme fixture (no seed block copied — dup gate), then
/// builds a `CatchupPlaybackModel` over the prepared request and drives the
/// read-only transport row via the `#if DEBUG` position/paused overrides — the
/// simulator can't decode the fake TS, so state is proved by the overrides, not
/// real video. `-tellyCatchupPaused` flips the paused pill on.
extension ContentView {
    @ViewBuilder var catchupTransportDemo: some View {
        if let model = catchupTransportModel,
           let request = model.state?.request ?? catchupTarget?.request {
            CatchupPlaybackScreen(model: model, request: request)
        } else {
            Color.black.ignoresSafeArea().task { prepareCatchupTransportDemo() }
        }
    }

    func prepareCatchupTransportDemo() {
        prepareCatchupDemo()
        guard let request = catchupTarget?.request else { return }
        let model = env.makeCatchupPlaybackModel(request: request)
        model.debugPosition = (request.durationMs * 45) / 100
        model.debugPaused = DebugLaunch.catchupPausedRequested(in: debugArgs)
        catchupTransportModel = model
    }
}
#endif
