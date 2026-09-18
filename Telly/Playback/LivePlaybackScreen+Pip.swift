#if os(iOS)
import SwiftUI
import AVKit

/// iOS/iPadOS Picture-in-Picture lifecycle for the live stage, split into a
/// sibling per the `+PanelView`/`+TrackPickerView` precedent. Learns device PiP
/// support on appear and starts system PiP when the model records a one-shot
/// ``LivePlaybackModel/pipRequested`` intent (from the quick-bar slot). VLCKit
/// owns the AVKit internals; here we only bridge the SwiftUI lifecycle.
extension LivePlaybackScreen {
    @ViewBuilder var pipLifecycle: some View {
        Color.clear
            .allowsHitTesting(false)
            .onAppear {
                model.isPipSupported = AVPictureInPictureController.isPictureInPictureSupported()
            }
            .onChange(of: model.pipRequested) { _, requested in
                guard requested else { return }
                (model.engine as? VLCKitPlayerEngine)?.startPip()
                model.pipRequested = false
            }
    }
}
#endif
