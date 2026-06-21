import Flutter
import UIKit
import BackgroundTasks
import Firebase

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // Configure Firebase
    FirebaseApp.configure()
    
    // Enable background app refresh
    UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
    
    // Initialize background task management
    if #available(iOS 13.0, *) {
      BackgroundTaskManager.shared.scheduleBackgroundAppRefresh()
      BackgroundTaskManager.shared.scheduleBackgroundProcessing()
    }
    
    // Initialize location services
    LocationManager.shared.startContinuousLocationUpdates()
    
    // Initialize network monitoring
    NetworkManager.shared.connectWebSocket()
    
    // Enable security protection
    SecurityManager.shared.enableAppProtection()
    SecurityManager.shared.enableDataProtection()
    
    // Register Flutter plugins
    GeneratedPluginRegistrant.register(with: self)
    
    // Setup method channel for iOS-specific functionality
    setupMethodChannels()
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func setupMethodChannels() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return
    }
    
    let backgroundChannel = FlutterMethodChannel(
      name: "com.xpsafeconnect.monitored-app/background-ios",
      binaryMessenger: controller.binaryMessenger
    )
    
    backgroundChannel.setMethodCallHandler { [weak self] call, result in
      self?.handleMethodCall(call, result: result)
    }
  }
  
  private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "startBackgroundTasks":
      if #available(iOS 13.0, *) {
        BackgroundTaskManager.shared.scheduleBackgroundAppRefresh()
        BackgroundTaskManager.shared.scheduleBackgroundProcessing()
      }
      result(true)
      
    case "stopBackgroundTasks":
      if #available(iOS 13.0, *) {
        BackgroundTaskManager.shared.cancelAllBackgroundTasks()
      }
      result(true)
      
    case "getCurrentLocation":
      LocationManager.shared.getCurrentLocation { location in
        if let location = location {
          let locationData = [
            "latitude": location.coordinate.latitude,
            "longitude": location.coordinate.longitude,
            "accuracy": location.horizontalAccuracy,
            "timestamp": location.timestamp.timeIntervalSince1970
          ]
          result(locationData)
        } else {
          result(FlutterError(code: "LOCATION_ERROR", message: "Failed to get location", details: nil))
        }
      }
      
    case "syncData":
      DataSyncManager.shared.syncAllData { success in
        result(success)
      }
      
    case "performSecurityScan":
      SecurityManager.shared.performSecurityScan { success in
        result(success)
      }
      
    case "getSecurityStatus":
      let status = SecurityManager.shared.getSecurityStatus()
      result(status)
      
    case "getSyncStatistics":
      let stats = DataSyncManager.shared.getSyncStatistics()
      result(stats)
      
    case "authenticateUser":
      SecurityManager.shared.authenticateWithBiometrics { success, error in
        if success {
          result(true)
        } else {
          result(FlutterError(code: "AUTH_ERROR", message: error?.localizedDescription ?? "Authentication failed", details: nil))
        }
      }
      
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  // MARK: - Background App Refresh
  
  override func application(
    _ application: UIApplication,
    performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    print("Background app refresh triggered")
    
    DataSyncManager.shared.handleBackgroundSync { success in
      completionHandler(success ? .newData : .failed)
    }
  }
  
  // MARK: - Silent Push Notifications
  
  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    print("Silent push notification received")
    
    if #available(iOS 13.0, *) {
      BackgroundTaskManager.shared.handleSilentPushNotification(userInfo: userInfo, completion: completionHandler)
    } else {
      // Fallback for iOS 12 and earlier
      DataSyncManager.shared.handleBackgroundSync { success in
        completionHandler(success ? .newData : .failed)
      }
    }
  }
  
  // MARK: - App Lifecycle
  
  override func applicationDidEnterBackground(_ application: UIApplication) {
    print("App entered background")
    
    // Schedule background tasks
    if #available(iOS 13.0, *) {
      BackgroundTaskManager.shared.scheduleBackgroundAppRefresh()
      BackgroundTaskManager.shared.scheduleBackgroundProcessing()
    }
    
    // Optimize sync for background mode
    DataSyncManager.shared.optimizeSync()
    
    super.applicationDidEnterBackground(application)
  }
  
  override func applicationWillEnterForeground(_ application: UIApplication) {
    print("App will enter foreground")
    
    // Resume normal operation
    DataSyncManager.shared.optimizeSync()
    
    // Reconnect WebSocket if needed
    if !NetworkManager.shared.networkAvailable {
      NetworkManager.shared.connectWebSocket()
    }
    
    super.applicationWillEnterForeground(application)
  }
  
  override func applicationDidBecomeActive(_ application: UIApplication) {
    print("App became active")
    
    // Perform immediate sync when app becomes active
    DataSyncManager.shared.syncPendingData()
    
    super.applicationDidBecomeActive(application)
  }
  
  override func applicationWillTerminate(_ application: UIApplication) {
    print("App will terminate")
    
    // Cleanup
    LocationManager.shared.stopLocationUpdates()
    NetworkManager.shared.disconnectWebSocket()
    
    super.applicationWillTerminate(application)
  }
}
