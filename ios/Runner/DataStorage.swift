import Foundation
import SQLite3

class DataStorage {
    static let shared = DataStorage()
    
    private var db: OpaquePointer?
    private let dbQueue = DispatchQueue(label: "dataStorageQueue", qos: .utility)
    
    private init() {
        openDatabase()
        createTables()
    }
    
    deinit {
        closeDatabase()
    }
    
    // MARK: - Database Management
    
    private func openDatabase() {
        let fileURL = try! FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("MonitoredAppData.sqlite")
        
        if sqlite3_open(fileURL.path, &db) == SQLITE_OK {
            print("Successfully opened database at \(fileURL.path)")
        } else {
            print("Failed to open database")
        }
    }
    
    private func closeDatabase() {
        if db != nil {
            sqlite3_close(db)
            db = nil
        }
    }
    
    private func createTables() {
        let createLocationTable = """
            CREATE TABLE IF NOT EXISTS location_data (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                latitude REAL NOT NULL,
                longitude REAL NOT NULL,
                accuracy REAL,
                altitude REAL,
                altitude_accuracy REAL,
                speed REAL,
                course REAL,
                timestamp REAL NOT NULL,
                collected_at REAL NOT NULL,
                synced INTEGER DEFAULT 0,
                emergency INTEGER DEFAULT 0
            );
        """
        
        let createDeviceStatusTable = """
            CREATE TABLE IF NOT EXISTS device_status (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                battery_level REAL,
                battery_state INTEGER,
                orientation INTEGER,
                timestamp REAL NOT NULL,
                synced INTEGER DEFAULT 0
            );
        """
        
        let createAppUsageTable = """
            CREATE TABLE IF NOT EXISTS app_usage (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                app_state INTEGER,
                background_time_remaining REAL,
                timestamp REAL NOT NULL,
                synced INTEGER DEFAULT 0
            );
        """
        
        let createGeofenceEventsTable = """
            CREATE TABLE IF NOT EXISTS geofence_events (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                region_id TEXT NOT NULL,
                event_type TEXT NOT NULL,
                timestamp REAL NOT NULL,
                synced INTEGER DEFAULT 0
            );
        """
        
        let createEmergencyLocationTable = """
            CREATE TABLE IF NOT EXISTS emergency_location (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                latitude REAL NOT NULL,
                longitude REAL NOT NULL,
                accuracy REAL,
                altitude REAL,
                speed REAL,
                timestamp REAL NOT NULL,
                collected_at REAL NOT NULL,
                synced INTEGER DEFAULT 0
            );
        """
        
        let createSyncQueueTable = """
            CREATE TABLE IF NOT EXISTS sync_queue (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                data_type TEXT NOT NULL,
                payload TEXT NOT NULL,
                priority INTEGER DEFAULT 1,
                created_at REAL NOT NULL,
                last_attempt REAL,
                attempt_count INTEGER DEFAULT 0,
                status TEXT DEFAULT 'pending'
            );
        """
        
        let tables = [
            createLocationTable,
            createDeviceStatusTable,
            createAppUsageTable,
            createGeofenceEventsTable,
            createEmergencyLocationTable,
            createSyncQueueTable
        ]
        
        for tableSQL in tables {
            if sqlite3_exec(db, tableSQL, nil, nil, nil) != SQLITE_OK {
                let errmsg = String(cString: sqlite3_errmsg(db)!)
                print("Error creating table: \(errmsg)")
            }
        }
        
        // Create indexes for better performance
        let indexes = [
            "CREATE INDEX IF NOT EXISTS idx_location_timestamp ON location_data(timestamp);",
            "CREATE INDEX IF NOT EXISTS idx_location_synced ON location_data(synced);",
            "CREATE INDEX IF NOT EXISTS idx_sync_queue_status ON sync_queue(status);",
            "CREATE INDEX IF NOT EXISTS idx_sync_queue_priority ON sync_queue(priority);"
        ]
        
        for indexSQL in indexes {
            sqlite3_exec(db, indexSQL, nil, nil, nil)
        }
    }
    
    // MARK: - Data Storage
    
    func store(data: [String: Any], type: String) {
        dbQueue.async {
            switch type {
            case "location":
                self.storeLocationData(data)
            case "device_status":
                self.storeDeviceStatus(data)
            case "app_usage":
                self.storeAppUsage(data)
            case "geofence_event":
                self.storeGeofenceEvent(data)
            case "emergency_location":
                self.storeEmergencyLocation(data)
            default:
                print("Unknown data type: \(type)")
            }
        }
    }
    
    private func storeLocationData(_ data: [String: Any]) {
        let sql = """
            INSERT INTO location_data (latitude, longitude, accuracy, altitude, altitude_accuracy, speed, course, timestamp, collected_at, emergency)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_double(statement, 1, data["latitude"] as? Double ?? 0.0)
            sqlite3_bind_double(statement, 2, data["longitude"] as? Double ?? 0.0)
            sqlite3_bind_double(statement, 3, data["accuracy"] as? Double ?? 0.0)
            sqlite3_bind_double(statement, 4, data["altitude"] as? Double ?? 0.0)
            sqlite3_bind_double(statement, 5, data["altitude_accuracy"] as? Double ?? 0.0)
            sqlite3_bind_double(statement, 6, data["speed"] as? Double ?? 0.0)
            sqlite3_bind_double(statement, 7, data["course"] as? Double ?? 0.0)
            sqlite3_bind_double(statement, 8, data["timestamp"] as? Double ?? 0.0)
            sqlite3_bind_double(statement, 9, data["collected_at"] as? Double ?? Date().timeIntervalSince1970)
            sqlite3_bind_int(statement, 10, (data["emergency"] as? Bool ?? false) ? 1 : 0)
            
            if sqlite3_step(statement) == SQLITE_DONE {
                print("Location data stored successfully")
                
                // Add to sync queue
                addToSyncQueue(dataType: "location", payload: data)
            } else {
                let errmsg = String(cString: sqlite3_errmsg(db)!)
                print("Error storing location data: \(errmsg)")
            }
        }
        
        sqlite3_finalize(statement)
    }
    
    private func storeDeviceStatus(_ data: [String: Any]) {
        let sql = """
            INSERT INTO device_status (battery_level, battery_state, orientation, timestamp)
            VALUES (?, ?, ?, ?);
        """
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_double(statement, 1, data["battery_level"] as? Double ?? 0.0)
            sqlite3_bind_int(statement, 2, data["battery_state"] as? Int32 ?? 0)
            sqlite3_bind_int(statement, 3, data["orientation"] as? Int32 ?? 0)
            sqlite3_bind_double(statement, 4, data["timestamp"] as? Double ?? Date().timeIntervalSince1970)
            
            if sqlite3_step(statement) == SQLITE_DONE {
                print("Device status stored successfully")
                addToSyncQueue(dataType: "device_status", payload: data)
            }
        }
        
        sqlite3_finalize(statement)
    }
    
    private func storeAppUsage(_ data: [String: Any]) {
        let sql = """
            INSERT INTO app_usage (app_state, background_time_remaining, timestamp)
            VALUES (?, ?, ?);
        """
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, data["app_state"] as? Int32 ?? 0)
            sqlite3_bind_double(statement, 2, data["background_time_remaining"] as? Double ?? 0.0)
            sqlite3_bind_double(statement, 3, data["timestamp"] as? Double ?? Date().timeIntervalSince1970)
            
            if sqlite3_step(statement) == SQLITE_DONE {
                print("App usage stored successfully")
                addToSyncQueue(dataType: "app_usage", payload: data)
            }
        }
        
        sqlite3_finalize(statement)
    }
    
    private func storeGeofenceEvent(_ data: [String: Any]) {
        let sql = """
            INSERT INTO geofence_events (region_id, event_type, timestamp)
            VALUES (?, ?, ?);
        """
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            let regionId = data["region_id"] as? String ?? ""
            let eventType = data["event_type"] as? String ?? ""
            
            sqlite3_bind_text(statement, 1, regionId, -1, nil)
            sqlite3_bind_text(statement, 2, eventType, -1, nil)
            sqlite3_bind_double(statement, 3, data["timestamp"] as? Double ?? Date().timeIntervalSince1970)
            
            if sqlite3_step(statement) == SQLITE_DONE {
                print("Geofence event stored successfully")
                addToSyncQueue(dataType: "geofence_event", payload: data, priority: 2) // Higher priority
            }
        }
        
        sqlite3_finalize(statement)
    }
    
    private func storeEmergencyLocation(_ data: [String: Any]) {
        let sql = """
            INSERT INTO emergency_location (latitude, longitude, accuracy, altitude, speed, timestamp, collected_at)
            VALUES (?, ?, ?, ?, ?, ?, ?);
        """
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_double(statement, 1, data["latitude"] as? Double ?? 0.0)
            sqlite3_bind_double(statement, 2, data["longitude"] as? Double ?? 0.0)
            sqlite3_bind_double(statement, 3, data["accuracy"] as? Double ?? 0.0)
            sqlite3_bind_double(statement, 4, data["altitude"] as? Double ?? 0.0)
            sqlite3_bind_double(statement, 5, data["speed"] as? Double ?? 0.0)
            sqlite3_bind_double(statement, 6, data["timestamp"] as? Double ?? 0.0)
            sqlite3_bind_double(statement, 7, data["collected_at"] as? Double ?? Date().timeIntervalSince1970)
            
            if sqlite3_step(statement) == SQLITE_DONE {
                print("Emergency location stored successfully")
                addToSyncQueue(dataType: "emergency_location", payload: data, priority: 3) // Highest priority
            }
        }
        
        sqlite3_finalize(statement)
    }
    
    // MARK: - Sync Queue Management
    
    private func addToSyncQueue(dataType: String, payload: [String: Any], priority: Int = 1) {
        do {
            let payloadData = try JSONSerialization.data(withJSONObject: payload, options: [])
            let payloadString = String(data: payloadData, encoding: .utf8) ?? ""
            
            let sql = """
                INSERT INTO sync_queue (data_type, payload, priority, created_at)
                VALUES (?, ?, ?, ?);
            """
            
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, dataType, -1, nil)
                sqlite3_bind_text(statement, 2, payloadString, -1, nil)
                sqlite3_bind_int(statement, 3, Int32(priority))
                sqlite3_bind_double(statement, 4, Date().timeIntervalSince1970)
                
                if sqlite3_step(statement) == SQLITE_DONE {
                    print("Added to sync queue: \(dataType)")
                }
            }
            
            sqlite3_finalize(statement)
        } catch {
            print("Error adding to sync queue: \(error)")
        }
    }
    
    func getPendingSyncItems(limit: Int = 50) -> [[String: Any]] {
        var items: [[String: Any]] = []
        
        let sql = """
            SELECT id, data_type, payload, priority, created_at, attempt_count
            FROM sync_queue
            WHERE status = 'pending'
            ORDER BY priority DESC, created_at ASC
            LIMIT ?;
        """
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, Int32(limit))
            
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = sqlite3_column_int(statement, 0)
                let dataType = String(cString: sqlite3_column_text(statement, 1))
                let payload = String(cString: sqlite3_column_text(statement, 2))
                let priority = sqlite3_column_int(statement, 3)
                let createdAt = sqlite3_column_double(statement, 4)
                let attemptCount = sqlite3_column_int(statement, 5)
                
                if let payloadData = payload.data(using: .utf8),
                   let payloadDict = try? JSONSerialization.jsonObject(with: payloadData, options: []) as? [String: Any] {
                    
                    let item = [
                        "id": Int(id),
                        "data_type": dataType,
                        "payload": payloadDict,
                        "priority": Int(priority),
                        "created_at": createdAt,
                        "attempt_count": Int(attemptCount)
                    ] as [String: Any]
                    
                    items.append(item)
                }
            }
        }
        
        sqlite3_finalize(statement)
        return items
    }
    
    func markSyncItemAsCompleted(id: Int) {
        let sql = "UPDATE sync_queue SET status = 'completed' WHERE id = ?;"
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, Int32(id))
            sqlite3_step(statement)
        }
        
        sqlite3_finalize(statement)
    }
    
    func markSyncItemAsFailed(id: Int) {
        let sql = """
            UPDATE sync_queue
            SET status = 'failed', attempt_count = attempt_count + 1, last_attempt = ?
            WHERE id = ?;
        """
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_double(statement, 1, Date().timeIntervalSince1970)
            sqlite3_bind_int(statement, 2, Int32(id))
            sqlite3_step(statement)
        }
        
        sqlite3_finalize(statement)
    }
    
    // MARK: - Data Cleanup
    
    func cleanupOldData() {
        let cutoffTime = Date().timeIntervalSince1970 - (7 * 24 * 60 * 60) // 7 days ago
        
        let cleanupQueries = [
            "DELETE FROM location_data WHERE synced = 1 AND collected_at < \(cutoffTime);",
            "DELETE FROM device_status WHERE synced = 1 AND timestamp < \(cutoffTime);",
            "DELETE FROM app_usage WHERE synced = 1 AND timestamp < \(cutoffTime);",
            "DELETE FROM geofence_events WHERE synced = 1 AND timestamp < \(cutoffTime);",
            "DELETE FROM sync_queue WHERE status = 'completed' AND created_at < \(cutoffTime);"
        ]
        
        for query in cleanupQueries {
            sqlite3_exec(db, query, nil, nil, nil)
        }
        
        print("Old data cleanup completed")
    }
    
    func getDatabaseStatistics() -> [String: Int] {
        var stats: [String: Int] = [:]
        
        let queries = [
            "location_count": "SELECT COUNT(*) FROM location_data;",
            "device_status_count": "SELECT COUNT(*) FROM device_status;",
            "app_usage_count": "SELECT COUNT(*) FROM app_usage;",
            "geofence_events_count": "SELECT COUNT(*) FROM geofence_events;",
            "emergency_location_count": "SELECT COUNT(*) FROM emergency_location;",
            "pending_sync_count": "SELECT COUNT(*) FROM sync_queue WHERE status = 'pending';"
        ]
        
        for (key, query) in queries {
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
                if sqlite3_step(statement) == SQLITE_ROW {
                    stats[key] = Int(sqlite3_column_int(statement, 0))
                }
            }
            sqlite3_finalize(statement)
        }
        
        return stats
    }
}