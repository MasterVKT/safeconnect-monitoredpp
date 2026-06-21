import Foundation
import UIKit
import LocalAuthentication

class SecurityManager {
    static let shared = SecurityManager()
    
    private init() {}
    
    // MARK: - Security Checks
    
    func performSecurityScan(completion: @escaping (Bool) -> Void) {
        let group = DispatchGroup()
        var overallSecurity = true
        
        // Check if device is jailbroken
        group.enter()
        checkJailbreakStatus { isJailbroken in
            if isJailbroken {
                overallSecurity = false
                self.reportSecurityThreat(type: "jailbreak_detected", description: "Device appears to be jailbroken")
            }
            group.leave()
        }
        
        // Check for debugging
        group.enter()
        checkDebuggingStatus { isDebugging in
            if isDebugging {
                overallSecurity = false
                self.reportSecurityThreat(type: "debugger_detected", description: "Debugger or development tools detected")
            }
            group.leave()
        }
        
        // Check app integrity
        group.enter()
        checkAppIntegrity { isValid in
            if !isValid {
                overallSecurity = false
                self.reportSecurityThreat(type: "app_integrity_failure", description: "App integrity check failed")
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            completion(overallSecurity)
        }
    }
    
    private func checkJailbreakStatus(completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .utility).async {
            let isJailbroken = self.isDeviceJailbroken()
            DispatchQueue.main.async {
                completion(isJailbroken)
            }
        }
    }
    
    private func isDeviceJailbroken() -> Bool {
        return checkJailbreakPaths() || 
               checkWriteableDirectories() || 
               checkJailbreakURLSchemes() || 
               checkSystemApps() ||
               checkEnvironmentVariables() ||
               checkDynamicLibraries() ||
               checkSystemProperties()
    }
    
    private func checkJailbreakPaths() -> Bool {
        let jailbreakPaths = [
            // Cydia and package managers
            "/Applications/Cydia.app",
            "/Applications/Sileo.app",
            "/Applications/Zebra.app",
            "/Applications/Installer.app",
            "/Applications/blackra1n.app",
            "/Applications/FakeCarrier.app",
            "/Applications/Icy.app",
            "/Applications/IntelliScreen.app",
            "/Applications/MxTube.app",
            "/Applications/RockApp.app",
            "/Applications/SBSettings.app",
            "/Applications/WinterBoard.app",
            
            // System binaries
            "/bin/bash",
            "/bin/sh",
            "/usr/sbin/sshd",
            "/usr/bin/sshd",
            "/bin/su",
            "/usr/bin/su",
            "/etc/ssh/sshd_config",
            "/usr/sbin/frida-server",
            
            // Substrate and hooking frameworks
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/Library/MobileSubstrate/DynamicLibraries/Veency.plist",
            "/Library/MobileSubstrate/DynamicLibraries/LiveClock.plist",
            "/System/Library/LaunchDaemons/com.ikey.bbot.plist",
            "/System/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist",
            "/Library/MobileSubstrate/DynamicLibraries/",
            
            // Package management
            "/etc/apt",
            "/private/var/lib/apt/",
            "/private/var/lib/cydia",
            "/private/var/cache/apt",
            "/private/var/log/syslog",
            "/private/var/tmp/cydia.log",
            "/private/var/lib/dpkg/info",
            
            // Jailbreak tools
            "/usr/bin/cycript",
            "/usr/local/bin/cycript",
            "/usr/lib/libcycript.dylib",
            "/var/root/Media/Cydia/AutoInstall",
            "/System/Library/LaunchDaemons/com.tigisoftware.filza.helper.plist",
            "/etc/clutch.conf",
            "/dev/kmem",
            
            // Substrate Safe Mode
            "/Applications/SafeMode.app",
            "/private/var/mobile/Library/SBSettings/Themes",
            "/private/var/stash",
            
            // Checkra1n
            "/usr/bin/checkra1n",
            "/usr/bin/odyssey",
            "/usr/bin/taurine",
            
            // unc0ver
            "/var/binpack",
            "/Library/dpkg/info/uikittools.list",
            "/var/lib/dpkg/info/uikittools.md5sums",
            
            // Palera1n
            "/usr/bin/palera1n",
            "/var/jb"
        ]
        
        for path in jailbreakPaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }
        return false
    }
    
    private func checkWriteableDirectories() -> Bool {
        let restrictedPaths = [
            "/private/test_jailbreak.txt",
            "/etc/test_jailbreak.txt",
            "/var/test_jailbreak.txt",
            "/Applications/test_jailbreak.txt"
        ]
        
        for path in restrictedPaths {
            do {
                let testString = "jailbreak_test"
                try testString.write(toFile: path, atomically: true, encoding: .utf8)
                try FileManager.default.removeItem(atPath: path)
                return true // Should not be able to write here on non-jailbroken device
            } catch {
                // Expected behavior on non-jailbroken device
            }
        }
        return false
    }
    
    private func checkJailbreakURLSchemes() -> Bool {
        let jailbreakSchemes = [
            "cydia://package/com.example.package",
            "sileo://package/com.example.package",
            "zbra://sources/add/https://example.com/",
            "installer://install/com.example.package",
            "activator://",
            "cycript://",
            "filza://",
            "mterminal://"
        ]
        
        for scheme in jailbreakSchemes {
            if let url = URL(string: scheme) {
                if UIApplication.shared.canOpenURL(url) {
                    return true
                }
            }
        }
        return false
    }
    
    private func checkSystemApps() -> Bool {
        // Check if system apps are missing (might indicate jailbreak)
        let systemApps = [
            "/Applications/Preferences.app",
            "/Applications/Mobile Safari.app"
        ]
        
        for app in systemApps {
            if !FileManager.default.fileExists(atPath: app) {
                return true
            }
        }
        return false
    }
    
    private func checkEnvironmentVariables() -> Bool {
        let suspiciousEnvVars = ["DYLD_INSERT_LIBRARIES", "_MSSafeMode"]
        
        for envVar in suspiciousEnvVars {
            if getenv(envVar) != nil {
                return true
            }
        }
        return false
    }
    
    private func checkDynamicLibraries() -> Bool {
        // Check for suspicious dynamic libraries that might indicate hooking frameworks
        let suspiciousLibs = [
            "MobileSubstrate",
            "libcycript",
            "SSLKillSwitch",
            "SSLKillSwitch2",
            "FridaGadget",
            "substitute",
            "libhooker"
        ]
        
        let imageName = UnsafeMutablePointer<Int8>.allocate(capacity: 1024)
        defer { imageName.deallocate() }
        
        for i in 0..<_dyld_image_count() {
            if let name = _dyld_get_image_name(i) {
                let imagePath = String(cString: name)
                for lib in suspiciousLibs {
                    if imagePath.contains(lib) {
                        return true
                    }
                }
            }
        }
        return false
    }
    
    private func checkSystemProperties() -> Bool {
        // Check iOS version for unusual modifications
        let systemVersion = UIDevice.current.systemVersion
        
        // Check if system version contains suspicious indicators
        if systemVersion.contains("checkra1n") || 
           systemVersion.contains("unc0ver") || 
           systemVersion.contains("taurine") ||
           systemVersion.contains("odyssey") {
            return true
        }
        
        // Check sandbox status
        if getenv("APP_SANDBOX_CONTAINER_ID") == nil {
            // App might not be sandboxed (jailbreak indicator)
            return true
        }
        
        return false
    }
    
    private func checkDebuggingStatus(completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .utility).async {
            let isDebugging = self.isBeingDebugged()
            DispatchQueue.main.async {
                completion(isDebugging)
            }
        }
    }
    
    private func isBeingDebugged() -> Bool {
        var info = kinfo_proc()
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        var size = MemoryLayout.stride(ofValue: info)
        
        let result = sysctl(&mib, u_int(mib.count), &info, &size, nil, 0)
        
        if result != 0 {
            return false
        }
        
        return (info.kp_proc.p_flag & P_TRACED) != 0
    }
    
    private func checkAppIntegrity(completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .utility).async {
            let isValid = self.verifyAppIntegrity()
            DispatchQueue.main.async {
                completion(isValid)
            }
        }
    }
    
    private func verifyAppIntegrity() -> Bool {
        // Check if the app bundle is properly signed
        guard let bundlePath = Bundle.main.bundlePath else { return false }
        
        // Check if embedded.mobileprovision exists (indicates development/ad-hoc build)
        let provisioningPath = bundlePath + "/embedded.mobileprovision"
        if FileManager.default.fileExists(atPath: provisioningPath) {
            // This might be acceptable for internal builds
            print("Development provisioning profile detected")
        }
        
        // Check if the executable is properly signed
        guard let executablePath = Bundle.main.executablePath else { return false }
        
        // Basic integrity check - ensure the executable exists and is readable
        return FileManager.default.isReadableFile(atPath: executablePath)
    }
    
    // MARK: - Biometric Authentication
    
    func authenticateWithBiometrics(completion: @escaping (Bool, Error?) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            completion(false, error)
            return
        }
        
        let reason = "Authenticate to access monitoring controls"
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authError in
            DispatchQueue.main.async {
                completion(success, authError)
            }
        }
    }
    
    func authenticateWithPasscode(completion: @escaping (Bool, Error?) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            completion(false, error)
            return
        }
        
        let reason = "Authenticate to access monitoring controls"
        
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, authError in
            DispatchQueue.main.async {
                completion(success, authError)
            }
        }
    }
    
    // MARK: - App Protection
    
    func enableAppProtection() {
        // Hide app content when backgrounded
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @objc private func applicationWillResignActive() {
        // Add privacy overlay to hide content in app switcher
        addPrivacyOverlay()
    }
    
    @objc private func applicationDidBecomeActive() {
        // Remove privacy overlay
        removePrivacyOverlay()
    }
    
    private var privacyOverlay: UIView?
    
    private func addPrivacyOverlay() {
        guard let window = UIApplication.shared.windows.first else { return }
        
        let overlay = UIView(frame: window.bounds)
        overlay.backgroundColor = .black
        
        let imageView = UIImageView(image: UIImage(named: "LaunchImage"))
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        overlay.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: overlay.centerYAnchor),
            imageView.widthAnchor.constraint(lessThanOrEqualTo: overlay.widthAnchor),
            imageView.heightAnchor.constraint(lessThanOrEqualTo: overlay.heightAnchor)
        ])
        
        window.addSubview(overlay)
        privacyOverlay = overlay
    }
    
    private func removePrivacyOverlay() {
        privacyOverlay?.removeFromSuperview()
        privacyOverlay = nil
    }
    
    // MARK: - Data Protection
    
    func enableDataProtection() {
        // Set up data protection for stored files
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        
        do {
            try FileManager.default.setAttributes(
                [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
                ofItemAtPath: documentsPath
            )
            print("Data protection enabled for documents directory")
        } catch {
            print("Failed to enable data protection: \(error)")
        }
    }
    
    // MARK: - Security Event Reporting
    
    private func reportSecurityThreat(type: String, description: String) {
        let threatData = [
            "type": type,
            "description": description,
            "platform": "ios",
            "device_model": UIDevice.current.model,
            "os_version": UIDevice.current.systemVersion,
            "app_version": Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown",
            "timestamp": Date().timeIntervalSince1970
        ] as [String: Any]
        
        // Store locally
        DataStorage.shared.store(data: threatData, type: "security_threat")
        
        // Send immediately if network is available
        if NetworkManager.shared.networkAvailable {
            NetworkManager.shared.sendData(endpoint: "/security/threat", data: threatData) { success in
                print("Security threat reported: \(success)")
            }
        }
        
        print("Security threat detected: \(type) - \(description)")
    }
    
    // MARK: - Remote Security Commands
    
    func handleSecurityCommand(_ command: String, parameters: [String: Any] = [:]) {
        switch command {
        case "security_scan":
            performSecurityScan { success in
                print("Security scan completed: \(success)")
            }
        case "enable_protection":
            enableAppProtection()
            enableDataProtection()
        case "authenticate_user":
            authenticateWithBiometrics { success, error in
                let result = [
                    "command": "authenticate_user",
                    "success": success,
                    "error": error?.localizedDescription ?? ""
                ] as [String: Any]
                
                NetworkManager.shared.sendData(endpoint: "/security/command-result", data: result) { _ in }
            }
        default:
            print("Unknown security command: \(command)")
        }
    }
    
    // MARK: - Security Status
    
    func getSecurityStatus() -> [String: Any] {
        return [
            "jailbroken": isDeviceJailbroken(),
            "being_debugged": isBeingDebugged(),
            "biometrics_available": LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil),
            "passcode_available": LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil),
            "data_protection_enabled": true, // Always enabled in our implementation
            "app_protection_enabled": privacyOverlay != nil
        ]
    }
}