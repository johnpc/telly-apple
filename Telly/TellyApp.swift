import SwiftUI

/// App entry. One SwiftUI codebase compiled for iPhone, iPad and Apple TV;
/// platform-specific layout lives behind `#if os(tvOS)` and size-class checks
/// inside the views, never here.
@main
struct TellyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
