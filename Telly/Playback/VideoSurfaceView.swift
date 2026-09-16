import SwiftUI
import UIKit

/// Bridges a plain black `UIView` into SwiftUI and hands it to the engine as the
/// VLC render target. UIKit exists on iOS and tvOS alike, so one representable
/// serves both. All the moving parts live in the engine; this is pure glue.
struct VideoSurfaceView: UIViewRepresentable {
    let engine: VLCKitPlayerEngine

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        engine.drawable = view
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        engine.drawable = uiView
    }
}
