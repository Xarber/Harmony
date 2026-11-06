// SPDX-License-Identifier: AGPL-3.0-only
import Foundation
import CSQLite

/// A connection confined to its owning actor. SQLite handles are never shared across threads.
final class Database {
    private var handle: OpaquePointer?
    init(url: URL) throws {
        guard sqlite3_open(url.path, &handle) == SQLITE_OK else { sqlite3_close(handle); handle = nil; throw HarmonyError.storage("Cannot open library database.") }
        do {
            let version = Int(try rows("PRAGMA user_version").first?.first ?? "0") ?? 0
            guard version <= 1 else { throw HarmonyError.unsupported("This library was created by a newer Harmony version. Open it with that version; no schema changes were applied.") }
            try execute("PRAGMA foreign_keys=ON; PRAGMA journal_mode=WAL; PRAGMA busy_timeout=5000;")
            try execute("""
            CREATE TABLE IF NOT EXISTS tracks(id TEXT PRIMARY KEY, title TEXT NOT NULL, artist TEXT, album TEXT, json TEXT NOT NULL);
            CREATE INDEX IF NOT EXISTS track_title ON tracks(title COLLATE NOCASE);
            CREATE INDEX IF NOT EXISTS track_artist ON tracks(artist COLLATE NOCASE);
            CREATE INDEX IF NOT EXISTS track_album ON tracks(album COLLATE NOCASE);
            CREATE TABLE IF NOT EXISTS audio_files(id TEXT PRIMARY KEY, track_id TEXT NOT NULL REFERENCES tracks(id) ON DELETE CASCADE, sha256 TEXT UNIQUE NOT NULL, json TEXT NOT NULL);
            CREATE TABLE IF NOT EXISTS playlists(id TEXT PRIMARY KEY, json TEXT NOT NULL);
            CREATE TABLE IF NOT EXISTS lyrics(track_id TEXT PRIMARY KEY REFERENCES tracks(id) ON DELETE CASCADE, json TEXT NOT NULL);
            CREATE TABLE IF NOT EXISTS lyrics_revisions(id INTEGER PRIMARY KEY, track_id TEXT NOT NULL, json TEXT NOT NULL);
            CREATE TABLE IF NOT EXISTS metadata_revisions(id INTEGER PRIMARY KEY, track_id TEXT NOT NULL, json TEXT NOT NULL);
            CREATE TABLE IF NOT EXISTS ideas(id TEXT PRIMARY KEY, json TEXT NOT NULL);
            CREATE TABLE IF NOT EXISTS idea_revisions(id INTEGER PRIMARY KEY, idea_id TEXT NOT NULL, json TEXT NOT NULL);
            CREATE TABLE IF NOT EXISTS state(key TEXT PRIMARY KEY, json TEXT NOT NULL);
            PRAGMA user_version=1;
            """)
        } catch { sqlite3_close(handle); handle = nil; throw error }
    }
    deinit { sqlite3_close(handle) }
    func execute(_ sql: String, _ values: [String?] = []) throws {
        if values.isEmpty {
            guard sqlite3_exec(handle, sql, nil, nil, nil) == SQLITE_OK else { throw error() }; return
        }
        let statement = try prepare(sql, values); defer { sqlite3_finalize(statement) }
        guard sqlite3_step(statement) == SQLITE_DONE else { throw error() }
    }
    func rows(_ sql: String, _ values: [String?] = []) throws -> [[String]] {
        let statement = try prepare(sql, values); defer { sqlite3_finalize(statement) }
        var result: [[String]] = []
        while true {
            let status = sqlite3_step(statement)
            if status == SQLITE_DONE { return result }
            guard status == SQLITE_ROW else { throw error() }
            result.append((0..<sqlite3_column_count(statement)).map { index in
                sqlite3_column_text(statement, index).map { String(cString: $0) } ?? ""
            })
        }
    }
    func transaction<T>(_ body: () throws -> T) throws -> T {
        try execute("BEGIN IMMEDIATE")
        do { let value = try body(); try execute("COMMIT"); return value }
        catch { try? execute("ROLLBACK"); throw error }
    }
    private func prepare(_ sql: String, _ values: [String?]) throws -> OpaquePointer {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(handle, sql, -1, &statement, nil) == SQLITE_OK, let statement else { throw error() }
        for (index, value) in values.enumerated() {
            let result: Int32
            if let value {
                result = value.withCString { sqlite3_bind_text(statement, Int32(index + 1), $0, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self)) }
            } else { result = sqlite3_bind_null(statement, Int32(index + 1)) }
            guard result == SQLITE_OK else { sqlite3_finalize(statement); throw error() }
        }
        return statement
    }
    private func error() -> HarmonyError { .storage("SQLite: \(String(cString: sqlite3_errmsg(handle)))") }
}
func encode<T: Encodable>(_ value: T) throws -> String { String(decoding: try JSONEncoder().encode(value), as: UTF8.self) }
func decode<T: Decodable>(_ type: T.Type, _ text: String) throws -> T { try JSONDecoder().decode(type, from: Data(text.utf8)) }
