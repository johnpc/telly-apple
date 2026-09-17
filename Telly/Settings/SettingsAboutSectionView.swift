import SwiftUI

/// The "About" settings group: the app name, the real bundle version string
/// (short version with build), and — where a browser exists — a link to the
/// source repository. Apple TV has no web browser, so the link is compiled out
/// there and the URL is shown as plain text instead. No "send statistics"
/// toggle: there is no backend, so shipping one would be a dead control (§1.6).
struct SettingsAboutSectionView: View {
    var body: some View {
        Section("About") {
            LabeledContent("App", value: AboutInfo.appName)
            LabeledContent("Version", value: AboutInfo.version)
            #if os(tvOS)
            LabeledContent("Source", value: AboutInfo.sourceUrl.absoluteString)
            #else
            Link("Source Code", destination: AboutInfo.sourceUrl)
            #endif
        }
    }
}
