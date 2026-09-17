import Foundation
import Testing
@testable import Telly

/// The pure version formatter: the build is appended in parentheses when
/// present, dropped when missing/empty, and a missing short version falls back
/// to a dash. The bundle-derived `version` and static facts are non-empty.
struct AboutInfoTests {
    @Test func versionAppendsBuildWhenPresent() {
        #expect(AboutInfo.versionLabel(short: "1.2.0", build: "42") == "1.2.0 (42)")
    }

    @Test func versionDropsMissingOrEmptyBuild() {
        #expect(AboutInfo.versionLabel(short: "1.2.0", build: nil) == "1.2.0")
        #expect(AboutInfo.versionLabel(short: "1.2.0", build: "") == "1.2.0")
    }

    @Test func missingShortVersionFallsBackToDash() {
        #expect(AboutInfo.versionLabel(short: nil, build: "42") == "— (42)")
        #expect(AboutInfo.versionLabel(short: "", build: nil) == "—")
    }

    @Test func bundleFactsResolve() {
        #expect(!AboutInfo.version.isEmpty)
        #expect(AboutInfo.appName == "Telly")
        #expect(AboutInfo.sourceUrl.scheme == "https")
    }
}
