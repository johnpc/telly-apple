import Foundation

/// Static "About" facts surfaced in Settings: the app name, a version string
/// derived from the bundle, and the source-code link. `versionLabel` is the pure
/// formatter (short version, with the build appended in parentheses when
/// present) so the display logic is testable without a real `Bundle`; `version`
/// applies it to the running bundle's Info dictionary.
enum AboutInfo {
    /// The user-facing application name.
    static let appName = "Telly"

    /// The project's public source repository.
    static let sourceUrl = URL(string: "https://github.com/johncorser/telly")!

    /// The display version: the short version, with `(build)` appended when a
    /// non-empty build is supplied. A missing short version falls back to a dash.
    static func versionLabel(short: String?, build: String?) -> String {
        let version = (short?.isEmpty == false) ? short! : "—"
        guard let build, !build.isEmpty else { return version }
        return "\(version) (\(build))"
    }

    /// The running bundle's version label from its Info dictionary.
    static var version: String {
        let info = Bundle.main.infoDictionary
        return versionLabel(short: info?["CFBundleShortVersionString"] as? String,
                            build: info?["CFBundleVersion"] as? String)
    }
}
