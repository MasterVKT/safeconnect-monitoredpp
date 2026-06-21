import Foundation
import Network

class NetworkManager {
    static let shared = NetworkManager()
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private var isConnected = false
    private var connectionType: NWInterface.InterfaceType?
    
    private init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.isConnected = path.status == .satisfied
            
            // Determine connection type
            if path.usesInterfaceType(.wifi) {
                self?.connectionType = .wifi
            } else if path.usesInterfaceType(.cellular) {
                self?.connectionType = .cellular
            } else {
                self?.connectionType = nil
            }
            
            print("Network status changed - Connected: \(self?.isConnected ?? false), Type: \(self?.connectionType?.rawValue ?? 0)")
            
            // Trigger sync when connection is restored
            if self?.isConnected == true {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    DataSyncManager.shared.syncPendingData()
                }
            }
        }
        
        monitor.start(queue: queue)
    }
    
    // MARK: - Network Status
    
    var networkAvailable: Bool {
        return isConnected
    }
    
    var isWiFiConnected: Bool {
        return isConnected && connectionType == .wifi
    }
    
    var isCellularConnected: Bool {
        return isConnected && connectionType == .cellular
    }
    
    // MARK: - HTTP Requests
    
    func sendHeartbeat(completion: @escaping (Bool) -> Void) {
        guard networkAvailable else {
            completion(false)
            return
        }
        
        let heartbeatData = [
            "type": "heartbeat",
            "timestamp": Date().timeIntervalSince1970,
            "platform": "ios",
            "app_version": getAppVersion(),
            "os_version": UIDevice.current.systemVersion
        ] as [String: Any]
        
        sendData(endpoint: "/heartbeat", data: heartbeatData) { success in
            completion(success)
        }
    }
    
    func sendData(endpoint: String, data: [String: Any], completion: @escaping (Bool) -> Void) {
        guard networkAvailable else {
            completion(false)
            return
        }
        
        guard let baseURL = getBaseURL(),
              let url = URL(string: baseURL + endpoint) else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authentication token if available
        if let token = getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data, options: [])
            request.httpBody = jsonData
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Network request error: \(error.localizedDescription)")
                        completion(false)
                        return
                    }
                    
                    if let httpResponse = response as? HTTPURLResponse {
                        let success = (200...299).contains(httpResponse.statusCode)
                        if !success {
                            print("HTTP error: \(httpResponse.statusCode)")
                        }
                        completion(success)
                    } else {
                        completion(false)
                    }
                }
            }
            
            task.resume()
            
        } catch {
            print("JSON serialization error: \(error)")
            completion(false)
        }
    }
    
    func uploadBatch(data: [[String: Any]], completion: @escaping (Bool) -> Void) {
        guard networkAvailable else {
            completion(false)
            return
        }
        
        let batchData = [
            "batch": data,
            "timestamp": Date().timeIntervalSince1970,
            "platform": "ios"
        ] as [String: Any]
        
        sendData(endpoint: "/data/batch", data: batchData, completion: completion)
    }
    
    // MARK: - WebSocket Connection
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var pingTimer: Timer?
    
    func connectWebSocket() {
        guard networkAvailable else { return }
        
        guard let baseURL = getWebSocketURL(),
              let url = URL(string: baseURL) else { return }
        
        var request = URLRequest(url: url)
        if let token = getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        webSocketTask = URLSession.shared.webSocketTask(with: request)
        webSocketTask?.resume()
        
        receiveMessage()
        startPing()
        
        print("WebSocket connected")
    }
    
    func disconnectWebSocket() {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        pingTimer?.invalidate()
        pingTimer = nil
        
        print("WebSocket disconnected")
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self?.handleWebSocketMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self?.handleWebSocketMessage(text)
                    }
                @unknown default:
                    break
                }
                
                // Continue receiving messages
                self?.receiveMessage()
                
            case .failure(let error):
                print("WebSocket receive error: \(error)")
                // Try to reconnect after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    self?.connectWebSocket()
                }
            }
        }
    }
    
    private func handleWebSocketMessage(_ message: String) {
        print("WebSocket message received: \(message)")
        
        guard let data = message.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return
        }
        
        let messageType = json["type"] as? String ?? ""
        
        switch messageType {
        case "command":
            handleRemoteCommand(json)
        case "emergency":
            handleEmergencyCommand(json)
        case "config":
            handleConfigUpdate(json)
        default:
            print("Unknown WebSocket message type: \(messageType)")
        }
    }
    
    private func handleRemoteCommand(_ data: [String: Any]) {
        let command = data["command"] as? String ?? ""
        
        switch command {
        case "collect_location":
            LocationManager.shared.getCurrentLocation { location in
                // Location will be automatically stored and synced
            }
        case "collect_emergency_location":
            LocationManager.shared.collectEmergencyLocation { location in
                // Emergency location will be automatically stored and synced
            }
        case "sync_data":
            DataSyncManager.shared.syncAllData { _ in }
        default:
            print("Unknown remote command: \(command)")
        }
    }
    
    private func handleEmergencyCommand(_ data: [String: Any]) {
        let emergency = data["emergency"] as? Bool ?? false
        
        if emergency {
            // Activate emergency mode
            BackgroundTaskManager.shared.handleSilentPushNotification(
                userInfo: ["command": "emergency_mode", "emergency": true]
            ) { _ in }
        }
    }
    
    private func handleConfigUpdate(_ data: [String: Any]) {
        // Handle configuration updates from server
        if let config = data["config"] as? [String: Any] {
            // Store configuration updates
            UserDefaults.standard.set(config, forKey: "server_config")
            UserDefaults.standard.synchronize()
        }
    }
    
    func sendWebSocketMessage(_ data: [String: Any]) {
        guard let webSocketTask = webSocketTask else { return }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data, options: [])
            let message = URLSessionWebSocketTask.Message.data(jsonData)
            
            webSocketTask.send(message) { error in
                if let error = error {
                    print("WebSocket send error: \(error)")
                }
            }
        } catch {
            print("WebSocket message serialization error: \(error)")
        }
    }
    
    private func startPing() {
        pingTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.webSocketTask?.sendPing { error in
                if let error = error {
                    print("WebSocket ping error: \(error)")
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func getBaseURL() -> String? {
        // Get from app configuration
        return UserDefaults.standard.string(forKey: "api_base_url") ?? "https://api.xpsafeconnect.com"
    }
    
    private func getWebSocketURL() -> String? {
        // Get from app configuration
        return UserDefaults.standard.string(forKey: "websocket_url") ?? "wss://api.xpsafeconnect.com/ws"
    }
    
    private func getAuthToken() -> String? {
        // Get from secure storage
        return UserDefaults.standard.string(forKey: "auth_token")
    }
    
    private func getAppVersion() -> String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }
}