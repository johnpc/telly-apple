import Foundation
import GRDB

/// Owns the app's SQLite connection and schema migrations. Tests open an
/// in-memory queue which — per the GRDB choice — IS the test backend, so there
/// is no hand-written fake store; the app opens the file-backed `makeShared`.
struct AppDatabase {
    let queue: DatabaseQueue

    init(_ queue: DatabaseQueue) throws {
        self.queue = queue
        try Self.migrator.migrate(queue)
    }

    /// A fresh in-memory database carrying the current schema.
    static func makeInMemory() throws -> AppDatabase {
        try AppDatabase(DatabaseQueue())
    }

    /// The on-device database file under Application Support (created lazily).
    static func makeShared() throws -> AppDatabase {
        let support = try FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return try AppDatabase(DatabaseQueue(path: support.appendingPathComponent("telly.sqlite").path))
    }

    private static var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("v1-core") { db in
            try CoreSchema.createPlaylists(db)
            try CoreSchema.createChannels(db)
        }
        migrator.registerMigration("v2-epg") { db in
            try EpgSchema.createPrograms(db)
        }
        migrator.registerMigration("v3-history") { db in
            try HistorySchema.createWatchHistory(db)
        }
        migrator.registerMigration("v4-epg-sources") { db in
            try EpgSourceSchema.createEpgSources(db)
        }
        migrator.registerMigration("v5-custom-groups") { db in
            try CustomGroupSchema.createCustomGroups(db)
            try CustomGroupSchema.createCustomGroupMembers(db)
        }
        return migrator
    }
}
