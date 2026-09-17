import Foundation

/// The thin state/logic core behind the Backup/Restore settings section: it
/// hands the file exporter the current backup JSON and applies restored JSON
/// back through ``SettingsBackupManager``, republishing the playlist feed on
/// success. Malformed or throwing input is reported as a failure, never a crash
/// and never a partial write past what the manager already guards. The
/// `FileDocument`/`fileExporter`/`fileImporter` glue lives in the (view-layer)
/// section; this model is what the tests drive.
@MainActor
@Observable
final class SettingsBackupModel {
    /// The outcome of the most recent restore, surfaced to the user as an alert.
    enum Outcome: Equatable { case restored, failed }

    var outcome: Outcome?
    private let manager: SettingsBackupManager
    private let reload: () -> Void

    init(manager: SettingsBackupManager, reload: @escaping () -> Void) {
        self.manager = manager
        self.reload = reload
    }

    /// The backup JSON to write to the exported file; rethrows serialisation
    /// failures so the caller can report them rather than exporting a blank.
    func exportText() throws -> String { try manager.exportJson() }

    /// Applies restored backup text: a valid decode reloads the playlist feed
    /// and reports `.restored`; malformed or throwing input reports `.failed`
    /// and leaves the current state untouched.
    func restore(from text: String) {
        if (try? manager.importJson(text)) == true {
            reload()
            outcome = .restored
        } else {
            outcome = .failed
        }
    }
}
