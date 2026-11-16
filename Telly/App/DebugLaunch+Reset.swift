#if DEBUG
import Foundation

/// Wipe every piece of on-device state (SQLite database, `UserDefaults`, the
/// synced Keychain config) so a scenario or screenshot proof starts from a
/// genuine first launch no matter what the previous run left behind — the
/// deterministic foundation behind "there is no such thing as a flaky test".
/// RULE: any launch carrying a `-telly…` argument resets, unless it carries
/// `-tellyKeepState` (the relaunch-persistence scenarios). A plain launch (no
/// `-telly…` argument — a human using the DEBUG build) never resets.
/// The core takes every location explicitly so it is unit-testable against a
/// temp file and in-memory stores; `TellyApp.init` passes the real ones.
extension DebugLaunch {
    static func resetRequested(in args: [String]) -> Bool { args.contains("-tellyResetState") }
    static func keepStateRequested(in args: [String]) -> Bool { args.contains("-tellyKeepState") }

    /// Whether this launch wipes state: harness-driven (`-telly…`) and not opted out.
    static func shouldResetState(args: [String]) -> Bool {
        guard !keepStateRequested(in: args) else { return false }
        return args.contains { $0.hasPrefix("-telly") }
    }

    /// Runs the wipe when ``shouldResetState(args:)``; a no-op otherwise.
    static func resetStateIfRequested(args: [String]) {
        guard shouldResetState(args: args), let database = try? AppDatabase.sharedUrl(),
              let domain = Bundle.main.bundleIdentifier else { return }
        resetState(databaseUrl: database, defaults: .standard, domain: domain,
                   synced: KeychainSyncedConfigStore())
    }

    /// Deletes the database (and its WAL/SHM side files), drops the defaults
    /// domain, and clears the synced config so a restore cannot repopulate it.
    static func resetState(databaseUrl: URL, defaults: UserDefaults, domain: String,
                           synced: SyncedConfigStore, fileManager: FileManager = .default) {
        for suffix in ["", "-wal", "-shm"] {
            try? fileManager.removeItem(atPath: databaseUrl.path + suffix)
        }
        defaults.removePersistentDomain(forName: domain)
        synced.clear()
    }
}
#endif
