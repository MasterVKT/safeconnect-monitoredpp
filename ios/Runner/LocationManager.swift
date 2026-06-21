import Foundation
import CoreLocation
import UIKit

class LocationManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    
    private var locationManager: CLLocationManager
    private var locationCompletionHandler: ((CLLocation?) -> Void)?
    private var isCollectingLocation = false
    private var lastLocationUpdate = Date.distantPast
    private let minimumLocationInterval: TimeInterval = 30 // 30 seconds minimum between updates
    
    private override init() {
        locationManager = CLLocationManager()
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // 10 meters
        
        // Request permissions
        requestLocationPermissions()
    }
    
    private func requestLocationPermissions() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
        case .denied, .restricted:
            print("Location access denied or restricted")
        case .authorizedWhenInUse:
            locationManager.requestAlwaysAuthorization()
        case .authorizedAlways:
            setupBackgroundLocationUpdates()
        @unknown default:
            print("Unknown location authorization status")
        }
    }
    
    private func setupBackgroundLocationUpdates() {
        // Enable background location updates
        if CLLocationManager.locationServicesEnabled() {
            locationManager.allowsBackgroundLocationUpdates = true
            locationManager.pausesLocationUpdatesAutomatically = false
            locationManager.startUpdatingLocation()
            
            // Start significant location changes for background
            locationManager.startMonitoringSignificantLocationChanges()
            
            print("Background location updates enabled")
        }
    }
    
    // MARK: - Public Methods
    
    func getCurrentLocation(completion: @escaping (CLLocation?) -> Void) {
        // Rate limiting
        let now = Date()
        if now.timeIntervalSince(lastLocationUpdate) < minimumLocationInterval {
            completion(locationManager.location)
            return
        }
        
        guard CLLocationManager.locationServicesEnabled() else {
            completion(nil)
            return
        }
        
        guard locationManager.authorizationStatus == .authorizedAlways ||
              locationManager.authorizationStatus == .authorizedWhenInUse else {
            completion(nil)
            return
        }
        
        locationCompletionHandler = completion
        isCollectingLocation = true
        
        // Use one-time location request for immediate response
        locationManager.requestLocation()
        
        // Timeout after 10 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            if self.isCollectingLocation {
                self.isCollectingLocation = false
                self.locationCompletionHandler?(self.locationManager.location)
                self.locationCompletionHandler = nil
            }
        }
    }
    
    func startContinuousLocationUpdates() {
        guard CLLocationManager.locationServicesEnabled() else { return }
        guard locationManager.authorizationStatus == .authorizedAlways else { return }
        
        locationManager.startUpdatingLocation()
        locationManager.startMonitoringSignificantLocationChanges()
        
        // Register for background location updates if app goes to background
        if #available(iOS 9.0, *) {
            locationManager.allowsBackgroundLocationUpdates = true
        }
        
        print("Continuous location updates started")
    }
    
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        locationManager.stopMonitoringSignificantLocationChanges()
        
        if #available(iOS 9.0, *) {
            locationManager.allowsBackgroundLocationUpdates = false
        }
        
        print("Location updates stopped")
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Update last location time
        lastLocationUpdate = Date()
        
        // Store location data
        storeLocationData(location)
        
        // Handle completion if waiting for location
        if isCollectingLocation {
            isCollectingLocation = false
            locationCompletionHandler?(location)
            locationCompletionHandler = nil
        }
        
        print("Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager error: \(error.localizedDescription)")
        
        if isCollectingLocation {
            isCollectingLocation = false
            locationCompletionHandler?(nil)
            locationCompletionHandler = nil
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("Location authorization status changed: \(status.rawValue)")
        
        switch status {
        case .authorizedAlways:
            setupBackgroundLocationUpdates()
        case .authorizedWhenInUse:
            // Try to upgrade to always authorization
            manager.requestAlwaysAuthorization()
        case .denied, .restricted:
            print("Location access denied")
            stopLocationUpdates()
        case .notDetermined:
            manager.requestAlwaysAuthorization()
        @unknown default:
            print("Unknown authorization status")
        }
    }
    
    func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
        print("Location updates paused")
    }
    
    func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
        print("Location updates resumed")
    }
    
    // MARK: - Private Methods
    
    private func storeLocationData(_ location: CLLocation) {
        let locationData = [
            "latitude": location.coordinate.latitude,
            "longitude": location.coordinate.longitude,
            "accuracy": location.horizontalAccuracy,
            "altitude": location.altitude,
            "altitude_accuracy": location.verticalAccuracy,
            "speed": location.speed,
            "course": location.course,
            "timestamp": location.timestamp.timeIntervalSince1970,
            "collected_at": Date().timeIntervalSince1970
        ] as [String: Any]
        
        DataStorage.shared.store(data: locationData, type: "location")
        
        // If this is a significant location change, sync immediately
        if CLLocationManager.significantLocationChangeMonitoringAvailable() {
            DataSyncManager.shared.syncLocationData(immediate: true)
        }
    }
    
    // MARK: - Emergency Location
    
    func collectEmergencyLocation(completion: @escaping (CLLocation?) -> Void) {
        // Force immediate location collection for emergency
        guard CLLocationManager.locationServicesEnabled() else {
            completion(nil)
            return
        }
        
        // Temporarily increase accuracy for emergency
        let originalAccuracy = locationManager.desiredAccuracy
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        getCurrentLocation { location in
            // Restore original accuracy
            self.locationManager.desiredAccuracy = originalAccuracy
            
            if let location = location {
                // Mark as emergency location
                let emergencyLocationData = [
                    "latitude": location.coordinate.latitude,
                    "longitude": location.coordinate.longitude,
                    "accuracy": location.horizontalAccuracy,
                    "altitude": location.altitude,
                    "speed": location.speed,
                    "emergency": true,
                    "timestamp": location.timestamp.timeIntervalSince1970,
                    "collected_at": Date().timeIntervalSince1970
                ] as [String: Any]
                
                DataStorage.shared.store(data: emergencyLocationData, type: "emergency_location")
                
                // Sync immediately
                DataSyncManager.shared.syncEmergencyData { _ in }
            }
            
            completion(location)
        }
    }
    
    // MARK: - Geofencing Support
    
    func setupGeofencing(regions: [(latitude: Double, longitude: Double, radius: Double, identifier: String)]) {
        // Remove existing regions
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
        
        // Add new regions
        for regionInfo in regions {
            let coordinate = CLLocationCoordinate2D(latitude: regionInfo.latitude, longitude: regionInfo.longitude)
            let region = CLCircularRegion(center: coordinate, radius: regionInfo.radius, identifier: regionInfo.identifier)
            region.notifyOnEntry = true
            region.notifyOnExit = true
            
            locationManager.startMonitoring(for: region)
        }
        
        print("Geofencing setup for \(regions.count) regions")
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("Entered region: \(region.identifier)")
        
        let geofenceEvent = [
            "region_id": region.identifier,
            "event_type": "enter",
            "timestamp": Date().timeIntervalSince1970
        ] as [String: Any]
        
        DataStorage.shared.store(data: geofenceEvent, type: "geofence_event")
        
        // Trigger immediate sync for geofence events
        DataSyncManager.shared.syncLocationData(immediate: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("Exited region: \(region.identifier)")
        
        let geofenceEvent = [
            "region_id": region.identifier,
            "event_type": "exit",
            "timestamp": Date().timeIntervalSince1970
        ] as [String: Any]
        
        DataStorage.shared.store(data: geofenceEvent, type: "geofence_event")
        
        // Trigger immediate sync for geofence events
        DataSyncManager.shared.syncLocationData(immediate: true)
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("Geofencing monitoring failed for region \(region?.identifier ?? "unknown"): \(error.localizedDescription)")
    }
}