import Foundation

class DataSyncManager {
    static let shared = DataSyncManager()
    
    private let syncQueue = DispatchQueue(label: "dataSyncQueue", qos: .utility)
    private var isSyncing = false
    private var syncTimer: Timer?
    
    private init() {
        startPeriodicSync()
    }
    
    // MARK: - Sync Management
    
    private func startPeriodicSync() {
        // Sync every 5 minutes when app is active
        syncTimer = Timer.scheduledTimer(withTimeInterval: 300.0, repeats: true) { [weak self] _ in
            self?.syncPendingData()
        }
    }
    
    func syncPendingData() {
        guard !isSyncing else {
            print("Sync already in progress")
            return
        }
        
        guard NetworkManager.shared.networkAvailable else {
            print("No network available for sync")
            return
        }
        
        syncQueue.async {
            self.performSync()
        }
    }
    
    func syncAllData(completion: @escaping (Bool) -> Void) {
        guard !isSyncing else {
            completion(false)
            return
        }
        
        guard NetworkManager.shared.networkAvailable else {
            completion(false)
            return
        }
        
        syncQueue.async {
            self.performSync(completion: completion)
        }
    }
    
    func syncCriticalData(completion: @escaping (Bool) -> Void) {
        guard NetworkManager.shared.networkAvailable else {
            completion(false)
            return
        }
        
        syncQueue.async {
            self.performCriticalSync(completion: completion)
        }
    }
    
    func syncEmergencyData(completion: @escaping (Bool) -> Void) {
        guard NetworkManager.shared.networkAvailable else {
            completion(false)
            return
        }
        
        syncQueue.async {
            self.performEmergencySync(completion: completion)
        }
    }
    
    func syncLocationData(immediate: Bool = false) {
        if immediate {
            syncQueue.async {
                self.performLocationSync()
            }
        } else {
            // Schedule for next regular sync
            print("Location sync scheduled for next regular sync")
        }
    }
    
    // MARK: - Sync Implementation
    
    private func performSync(completion: ((Bool) -> Void)? = nil) {
        isSyncing = true
        
        let pendingItems = DataStorage.shared.getPendingSyncItems(limit: 100)
        
        guard !pendingItems.isEmpty else {
            isSyncing = false
            completion?(true)
            return
        }
        
        print("Syncing \(pendingItems.count) items")
        
        // Group items by type for batch upload
        var groupedItems: [String: [[String: Any]]] = [:]
        var itemIds: [Int] = []
        
        for item in pendingItems {
            guard let id = item["id"] as? Int,
                  let dataType = item["data_type"] as? String,
                  let payload = item["payload"] as? [String: Any] else {
                continue
            }
            
            itemIds.append(id)
            
            if groupedItems[dataType] == nil {
                groupedItems[dataType] = []
            }
            groupedItems[dataType]?.append(payload)
        }
        
        let group = DispatchGroup()
        var overallSuccess = true
        
        // Sync each data type
        for (dataType, items) in groupedItems {
            group.enter()
            
            syncDataType(dataType, items: items) { success in
                if !success {
                    overallSuccess = false
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            if overallSuccess {
                // Mark all items as completed
                for id in itemIds {
                    DataStorage.shared.markSyncItemAsCompleted(id: id)
                }
                print("Sync completed successfully")
            } else {
                // Mark failed items
                for id in itemIds {
                    DataStorage.shared.markSyncItemAsFailed(id: id)
                }
                print("Sync completed with some failures")
            }
            
            self.isSyncing = false
            completion?(overallSuccess)
        }
    }
    
    private func performCriticalSync(completion: @escaping (Bool) -> Void) {
        isSyncing = true
        
        // Get only high-priority items
        let pendingItems = DataStorage.shared.getPendingSyncItems(limit: 50)
        let criticalItems = pendingItems.filter { item in
            guard let priority = item["priority"] as? Int else { return false }
            return priority >= 2 // Priority 2 and above are critical
        }
        
        guard !criticalItems.isEmpty else {
            isSyncing = false
            completion(true)
            return
        }
        
        print("Syncing \(criticalItems.count) critical items")
        
        let batchData = criticalItems.compactMap { $0["payload"] as? [String: Any] }
        
        NetworkManager.shared.uploadBatch(data: batchData) { success in
            if success {
                for item in criticalItems {
                    if let id = item["id"] as? Int {
                        DataStorage.shared.markSyncItemAsCompleted(id: id)
                    }
                }
            } else {
                for item in criticalItems {
                    if let id = item["id"] as? Int {
                        DataStorage.shared.markSyncItemAsFailed(id: id)
                    }
                }
            }
            
            self.isSyncing = false
            completion(success)
        }
    }
    
    private func performEmergencySync(completion: @escaping (Bool) -> Void) {
        isSyncing = true
        
        // Get only emergency items
        let pendingItems = DataStorage.shared.getPendingSyncItems(limit: 50)
        let emergencyItems = pendingItems.filter { item in
            guard let dataType = item["data_type"] as? String else { return false }
            return dataType.contains("emergency")
        }
        
        guard !emergencyItems.isEmpty else {
            isSyncing = false
            completion(true)
            return
        }
        
        print("Syncing \(emergencyItems.count) emergency items")
        
        let batchData = emergencyItems.compactMap { $0["payload"] as? [String: Any] }
        
        // Use emergency endpoint for higher priority
        NetworkManager.shared.sendData(endpoint: "/emergency/data", data: ["items": batchData]) { success in
            if success {
                for item in emergencyItems {
                    if let id = item["id"] as? Int {
                        DataStorage.shared.markSyncItemAsCompleted(id: id)
                    }
                }
            } else {
                for item in emergencyItems {
                    if let id = item["id"] as? Int {
                        DataStorage.shared.markSyncItemAsFailed(id: id)
                    }
                }
            }
            
            self.isSyncing = false
            completion(success)
        }
    }
    
    private func performLocationSync() {
        let pendingItems = DataStorage.shared.getPendingSyncItems(limit: 50)
        let locationItems = pendingItems.filter { item in
            guard let dataType = item["data_type"] as? String else { return false }
            return dataType == "location" || dataType == "geofence_event"
        }
        
        guard !locationItems.isEmpty else { return }
        
        let batchData = locationItems.compactMap { $0["payload"] as? [String: Any] }
        
        NetworkManager.shared.sendData(endpoint: "/location/batch", data: ["locations": batchData]) { success in
            if success {
                for item in locationItems {
                    if let id = item["id"] as? Int {
                        DataStorage.shared.markSyncItemAsCompleted(id: id)
                    }
                }
                print("Location sync completed successfully")
            } else {
                print("Location sync failed")
            }
        }
    }
    
    private func syncDataType(_ dataType: String, items: [[String: Any]], completion: @escaping (Bool) -> Void) {
        let endpoint = getEndpointForDataType(dataType)
        let requestData = [
            "type": dataType,
            "items": items,
            "timestamp": Date().timeIntervalSince1970
        ] as [String: Any]
        
        NetworkManager.shared.sendData(endpoint: endpoint, data: requestData, completion: completion)
    }
    
    private func getEndpointForDataType(_ dataType: String) -> String {
        switch dataType {
        case "location":
            return "/data/location"
        case "device_status":
            return "/data/device-status"
        case "app_usage":
            return "/data/app-usage"
        case "geofence_event":
            return "/data/geofence"
        case "emergency_location":
            return "/emergency/location"
        default:
            return "/data/generic"
        }
    }
    
    // MARK: - Sync Strategy
    
    func optimizeSync() {
        // Adjust sync frequency based on network conditions
        if NetworkManager.shared.isWiFiConnected {
            // More frequent sync on WiFi
            restartSyncTimer(interval: 180.0) // 3 minutes
        } else if NetworkManager.shared.isCellularConnected {
            // Less frequent sync on cellular
            restartSyncTimer(interval: 600.0) // 10 minutes
        } else {
            // Stop sync when no network
            stopSyncTimer()
        }
    }
    
    private func restartSyncTimer(interval: TimeInterval) {
        syncTimer?.invalidate()
        syncTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.syncPendingData()
        }
    }
    
    private func stopSyncTimer() {
        syncTimer?.invalidate()
        syncTimer = nil
    }
    
    // MARK: - Manual Sync Controls
    
    func forceSyncNow(completion: @escaping (Bool) -> Void) {
        // Force immediate sync regardless of current state
        isSyncing = false
        syncAllData(completion: completion)
    }
    
    func getSyncStatistics() -> [String: Any] {
        let pendingItems = DataStorage.shared.getPendingSyncItems(limit: 1000)
        let dbStats = DataStorage.shared.getDatabaseStatistics()
        
        var typeCount: [String: Int] = [:]
        for item in pendingItems {
            if let dataType = item["data_type"] as? String {
                typeCount[dataType] = (typeCount[dataType] ?? 0) + 1
            }
        }
        
        return [
            "pending_sync_items": pendingItems.count,
            "items_by_type": typeCount,
            "database_stats": dbStats,
            "is_syncing": isSyncing,
            "network_available": NetworkManager.shared.networkAvailable,
            "connection_type": NetworkManager.shared.isWiFiConnected ? "wifi" : "cellular"
        ]
    }
    
    // MARK: - Background Sync
    
    func handleBackgroundSync(completion: @escaping (Bool) -> Void) {
        // Optimized sync for background execution
        guard NetworkManager.shared.networkAvailable else {
            completion(false)
            return
        }
        
        // Only sync critical and emergency data in background
        syncCriticalData { success in
            if success {
                self.syncEmergencyData(completion: completion)
            } else {
                completion(false)
            }
        }
    }
}