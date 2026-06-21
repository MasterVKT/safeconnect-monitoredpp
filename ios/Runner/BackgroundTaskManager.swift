import Foundation
import UIKit
import BackgroundTasks
import CoreLocation

@available(iOS 13.0, *)
class BackgroundTaskManager: NSObject {
    static let shared = BackgroundTaskManager()
    
    // Background task identifiers
    static let backgroundAppRefreshTaskId = "com.xpsafeconnect.monitored-app.refresh"
    static let backgroundProcessingTaskId = "com.xpsafeconnect.monitored-app.processing"
    
    private var backgroundAppRefreshTask: BGAppRefreshTask?
    private var backgroundProcessingTask: BGProcessingTask?
    
    private override init() {
        super.init()
        setupBackgroundTasks()
    }
    
    private func setupBackgroundTasks() {
        // Register background task handlers
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.backgroundAppRefreshTaskId,
            using: nil
        ) { task in
            self.handleBackgroundAppRefresh(task: task as! BGAppRefreshTask)
        }
        
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.backgroundProcessingTaskId,
            using: nil
        ) { task in
            self.handleBackgroundProcessing(task: task as! BGProcessingTask)
        }
    }
    
    // Handle background app refresh (frequent, short tasks)
    private func handleBackgroundAppRefresh(task: BGAppRefreshTask) {
        backgroundAppRefreshTask = task
        
        // Schedule next background app refresh
        scheduleBackgroundAppRefresh()
        
        // Set expiration handler
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
            self.backgroundAppRefreshTask = nil
        }
        
        // Perform background refresh tasks
        performBackgroundRefresh { success in
            task.setTaskCompleted(success: success)
            self.backgroundAppRefreshTask = nil
        }
    }
    
    // Handle background processing (longer tasks)
    private func handleBackgroundProcessing(task: BGProcessingTask) {
        backgroundProcessingTask = task
        
        // Schedule next background processing
        scheduleBackgroundProcessing()
        
        // Set expiration handler
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
            self.backgroundProcessingTask = nil
        }
        
        // Perform background processing tasks
        performBackgroundProcessing { success in
            task.setTaskCompleted(success: success)
            self.backgroundProcessingTask = nil
        }
    }
    
    private func performBackgroundRefresh(completion: @escaping (Bool) -> Void) {
        print("Performing background refresh...")
        
        let group = DispatchGroup()
        var overallSuccess = true
        
        // Collect essential data
        group.enter()
        collectEssentialData { success in
            if !success { overallSuccess = false }
            group.leave()
        }
        
        // Send heartbeat
        group.enter()
        sendHeartbeat { success in
            if !success { overallSuccess = false }
            group.leave()
        }
        
        // Sync critical data
        group.enter()
        syncCriticalData { success in
            if !success { overallSuccess = false }
            group.leave()
        }
        
        group.notify(queue: .main) {
            print("Background refresh completed with success: \(overallSuccess)")
            completion(overallSuccess)
        }
    }
    
    private func performBackgroundProcessing(completion: @escaping (Bool) -> Void) {
        print("Performing background processing...")
        
        let group = DispatchGroup()
        var overallSuccess = true
        
        // Full data collection
        group.enter()
        performFullDataCollection { success in
            if !success { overallSuccess = false }
            group.leave()
        }
        
        // Data synchronization
        group.enter()
        performDataSynchronization { success in
            if !success { overallSuccess = false }
            group.leave()
        }
        
        // Security checks
        group.enter()
        performSecurityChecks { success in
            if !success { overallSuccess = false }
            group.leave()
        }
        
        group.notify(queue: .main) {
            print("Background processing completed with success: \(overallSuccess)")
            completion(overallSuccess)
        }
    }
    
    // Schedule background app refresh
    func scheduleBackgroundAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: Self.backgroundAppRefreshTaskId)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("Background app refresh scheduled successfully")
        } catch {
            print("Failed to schedule background app refresh: \(error)")
        }
    }
    
    // Schedule background processing
    func scheduleBackgroundProcessing() {
        let request = BGProcessingTaskRequest(identifier: Self.backgroundProcessingTaskId)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 30 * 60) // 30 minutes
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("Background processing scheduled successfully")
        } catch {
            print("Failed to schedule background processing: \(error)")
        }
    }
    
    // Data collection methods
    private func collectEssentialData(completion: @escaping (Bool) -> Void) {
        // Collect location if available
        LocationManager.shared.getCurrentLocation { location in
            if let location = location {
                self.storeLocationData(location)
            }
            completion(true)
        }
    }
    
    private func performFullDataCollection(completion: @escaping (Bool) -> Void) {
        // Perform comprehensive data collection
        let group = DispatchGroup()
        
        // Collect device status
        group.enter()
        collectDeviceStatus {
            group.leave()
        }
        
        // Collect app usage statistics
        group.enter()
        collectAppUsageStats {
            group.leave()
        }
        
        group.notify(queue: .main) {
            completion(true)
        }
    }
    
    private func collectDeviceStatus(completion: @escaping () -> Void) {
        let batteryLevel = UIDevice.current.batteryLevel
        let batteryState = UIDevice.current.batteryState
        let orientation = UIDevice.current.orientation
        
        let deviceStatus = [
            "battery_level": batteryLevel,
            "battery_state": batteryState.rawValue,
            "orientation": orientation.rawValue,
            "timestamp": Date().timeIntervalSince1970
        ] as [String: Any]
        
        DataStorage.shared.store(data: deviceStatus, type: "device_status")
        completion()
    }
    
    private func collectAppUsageStats(completion: @escaping () -> Void) {
        // iOS has limited access to app usage statistics
        // Collect what's available through legitimate APIs
        let appState = UIApplication.shared.applicationState
        let backgroundTimeRemaining = UIApplication.shared.backgroundTimeRemaining
        
        let usageStats = [
            "app_state": appState.rawValue,
            "background_time_remaining": backgroundTimeRemaining,
            "timestamp": Date().timeIntervalSince1970
        ] as [String: Any]
        
        DataStorage.shared.store(data: usageStats, type: "app_usage")
        completion()
    }
    
    private func sendHeartbeat(completion: @escaping (Bool) -> Void) {
        NetworkManager.shared.sendHeartbeat { success in
            completion(success)
        }
    }
    
    private func syncCriticalData(completion: @escaping (Bool) -> Void) {
        DataSyncManager.shared.syncCriticalData { success in
            completion(success)
        }
    }
    
    private func performDataSynchronization(completion: @escaping (Bool) -> Void) {
        DataSyncManager.shared.syncAllData { success in
            completion(success)
        }
    }
    
    private func performSecurityChecks(completion: @escaping (Bool) -> Void) {
        SecurityManager.shared.performSecurityScan { success in
            completion(success)
        }
    }
    
    private func storeLocationData(_ location: CLLocation) {
        let locationData = [
            "latitude": location.coordinate.latitude,
            "longitude": location.coordinate.longitude,
            "accuracy": location.horizontalAccuracy,
            "altitude": location.altitude,
            "speed": location.speed,
            "timestamp": location.timestamp.timeIntervalSince1970
        ] as [String: Any]
        
        DataStorage.shared.store(data: locationData, type: "location")
    }
    
    // Cancel all background tasks
    func cancelAllBackgroundTasks() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.backgroundAppRefreshTaskId)
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.backgroundProcessingTaskId)
    }
}

// MARK: - Silent Push Notifications Support
extension BackgroundTaskManager {
    func handleSilentPushNotification(userInfo: [AnyHashable: Any], completion: @escaping (UIBackgroundFetchResult) -> Void) {
        print("Handling silent push notification")
        
        // Parse the silent push notification
        guard let command = userInfo["command"] as? String else {
            completion(.noData)
            return
        }
        
        // Handle different commands
        switch command {
        case "collect_data":
            collectEssentialData { success in
                completion(success ? .newData : .failed)
            }
        case "sync_data":
            syncCriticalData { success in
                completion(success ? .newData : .failed)
            }
        case "emergency_mode":
            handleEmergencyMode(userInfo: userInfo) { success in
                completion(success ? .newData : .failed)
            }
        default:
            completion(.noData)
        }
    }
    
    private func handleEmergencyMode(userInfo: [AnyHashable: Any], completion: @escaping (Bool) -> Void) {
        // Handle emergency mode activation via silent push
        let isEmergency = userInfo["emergency"] as? Bool ?? false
        
        if isEmergency {
            // Activate emergency data collection
            performEmergencyDataCollection { success in
                completion(success)
            }
        } else {
            completion(true)
        }
    }
    
    private func performEmergencyDataCollection(completion: @escaping (Bool) -> Void) {
        let group = DispatchGroup()
        var overallSuccess = true
        
        // Collect immediate location
        group.enter()
        LocationManager.shared.getCurrentLocation { location in
            if let location = location {
                self.storeLocationData(location)
                // Mark as emergency location
                var emergencyData = [
                    "latitude": location.coordinate.latitude,
                    "longitude": location.coordinate.longitude,
                    "accuracy": location.horizontalAccuracy,
                    "emergency": true,
                    "timestamp": Date().timeIntervalSince1970
                ] as [String: Any]
                
                DataStorage.shared.store(data: emergencyData, type: "emergency_location")
            } else {
                overallSuccess = false
            }
            group.leave()
        }
        
        // Send immediate sync
        group.enter()
        DataSyncManager.shared.syncEmergencyData { success in
            if !success { overallSuccess = false }
            group.leave()
        }
        
        group.notify(queue: .main) {
            completion(overallSuccess)
        }
    }
}