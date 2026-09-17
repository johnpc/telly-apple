import Foundation

/// Encodes/decodes a ``BackupPayload`` to and from pretty-printed JSON text —
/// the Apple mirror of Android's `BackupCodec`. Decoding is tolerant: unknown
/// keys are ignored (forward-compat) and any malformed input yields nil rather
/// than throwing, so an imported file can never crash the app. Pure: no file
/// IO or persistence types, so the round-trip is fully unit-testable.
enum BackupCodec {
    /// Serialises `payload` to stable, human-readable JSON (sorted keys so the
    /// output is deterministic across runs).
    static func encode(_ payload: BackupPayload) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        // The payload is all String/Int/nested-Codable, so encoding never fails;
        // the empty-string fallback is unreachable and kept only for total-ness.
        return String(decoding: (try? encoder.encode(payload)) ?? Data(), as: UTF8.self)
    }

    /// Parses backup JSON, returning nil for malformed input (never throwing).
    static func decode(_ text: String) -> BackupPayload? {
        try? JSONDecoder().decode(BackupPayload.self, from: Data(text.utf8))
    }
}
