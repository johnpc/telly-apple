import SwiftUI

/// App entry. One SwiftUI codebase compiled for iPhone, iPad and Apple TV;
/// platform-specific layout lives behind `#if os(tvOS)` and size-class checks
/// inside the views, never here.
@main
struct TellyApp: App {
    init() {
        #if DEBUG
        // Harness launches (any `-telly…` argument, unless `-tellyKeepState`) wipe
        // on-device state BEFORE any store opens, so every acceptance scenario and
        // screenshot proof starts from a true first launch.
        DebugLaunch.resetStateIfRequested(args: ProcessInfo.processInfo.arguments)
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
