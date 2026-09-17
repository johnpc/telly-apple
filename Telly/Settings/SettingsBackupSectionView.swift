import SwiftUI

/// The "Backup" settings section. On iPhone/iPad it exports the current backup
/// JSON to a Files-app document and restores one back through
/// ``SettingsBackupModel``; the outcome is reported as an alert. On Apple TV —
/// which has no user-visible filesystem — the export/import surface is compiled
/// out and a disabled note is shown instead (§Slice 6). Pure presentation: all
/// decode/restore logic lives in the model.
struct SettingsBackupSectionView: View {
    let model: SettingsBackupModel
    #if !os(tvOS)
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var document = BackupDocument(text: "")
    #endif

    var body: some View {
        Section("Backup") {
            #if os(tvOS)
            Text("Backup is not available on Apple TV.")
                .foregroundStyle(.secondary)
            #else
            Button("Export Backup", action: export)
            Button("Restore Backup") { isImporting = true }
            #endif
        }
        #if !os(tvOS)
        .fileExporter(isPresented: $isExporting, document: document,
                      contentType: .json, defaultFilename: "telly-backup") { _ in }
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.json]) { result in
            if case let .success(url) = result { restore(from: url) }
        }
        .alert("Backup", isPresented: alertBinding) {
            Button("OK") { model.outcome = nil }
        } message: {
            Text(model.outcome == .restored ? "Backup restored."
                 : "Could not restore backup.")
        }
        #endif
    }

    #if !os(tvOS)
    private var alertBinding: Binding<Bool> {
        Binding(get: { model.outcome != nil },
                set: { if !$0 { model.outcome = nil } })
    }

    private func export() {
        guard let text = try? model.exportText() else { model.outcome = .failed; return }
        document = BackupDocument(text: text)
        isExporting = true
    }

    private func restore(from url: URL) {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            model.outcome = .failed
            return
        }
        model.restore(from: text)
    }
    #endif
}
