#if !os(tvOS)
import SwiftUI
import UniformTypeIdentifiers

/// The `FileDocument` the Backup section hands ``SwiftUI/View/fileExporter`` — a
/// plain UTF-8 JSON wrapper around the backup text produced by
/// ``SettingsBackupManager``. Restore does NOT flow through here: `fileImporter`
/// yields a URL the section reads directly, so this type only serialises out.
/// Compiled out on tvOS, which has no user-visible filesystem / document browser.
struct BackupDocument: FileDocument {
    static let readableContentTypes: [UTType] = [.json]
    var text: String

    init(text: String) { self.text = text }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        text = string
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(text.utf8))
    }
}
#endif
