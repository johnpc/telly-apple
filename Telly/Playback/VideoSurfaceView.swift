import SwiftUI
import UIKit

/// Bridges a plain black `UIView` into SwiftUI and hands it to the engine as the
/// VLC render target. UIKit exists on iOS and tvOS alike, so one representable
/// serves both. All the moving parts live in the engine; this is pure glue.
struct VideoSurfaceView: UIViewRepresentable {
    let engine: VLCKitPlayerEngine

    func makeUIView(context: Context) -> UIView {
        #if os(iOS)
        // iOS renders into the PiP-capable drawable so VLCKit can start a PiP
        // window on request; tvOS (no system PiP) keeps the plain UIView path.
        let view = PipDrawableView(engine: engine)
        engine.useDrawable(view)
        return view
        #else
        let view = UIView()
        view.backgroundColor = .black
        engine.drawable = view
        return view
        #endif
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        #if os(iOS)
        if let drawable = uiView as? PipDrawableView { engine.useDrawable(drawable) }
        #else
        engine.drawable = uiView
        #endif
    }
}
