import GRDB

/// Owns the app's SQLite connection and schema migrations. Tests open an
/// in-memory queue which — per the GRDB choice — IS the test backend, so there
/// is no hand-written fake store. The production file-backed opener arrives
/// with the app-wiring slice that consumes it.
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

    private static var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("v1-core") { db in
            try CoreSchema.createPlaylists(db)
            try CoreSchema.createChannels(db)
        }
        return migrator
    }
}
