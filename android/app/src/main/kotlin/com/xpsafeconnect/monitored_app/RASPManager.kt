package com.xpsafeconnect.monitored_app

import android.content.Context
import android.content.pm.PackageManager
import android.content.pm.Signature
import android.os.Debug
import android.util.Log
import java.io.ByteArrayInputStream
import java.security.MessageDigest
import java.security.cert.CertificateFactory
import java.security.cert.X509Certificate
import java.util.*
import kotlin.system.measureTimeMillis

class RASPManager(private val context: Context) {
    companion object {
        private const val TAG = "RASPManager"
        // Expected signature hash of the legitimate app (replace with actual)
        private const val EXPECTED_SIGNATURE_HASH = "YOUR_EXPECTED_SIGNATURE_HASH"
        // Maximum allowed execution time for critical operations (ms)
        private const val MAX_EXECUTION_TIME = 100
        // Expected package name
        private const val EXPECTED_PACKAGE_NAME = "com.xpsafeconnect.monitored_app"
    }

    private var isProtectionEnabled = false
    private val protectionChecks = mutableMapOf<String, Boolean>()

    /**
     * Initializes and enables all RASP protections
     */
    fun enableProtection(): Boolean {
        return try {
            Log.d(TAG, "Enabling RASP protection")
            
            // Perform initial integrity checks
            val checksPass = performIntegrityChecks()
            
            if (checksPass) {
                enableContinuousProtection()
                isProtectionEnabled = true
                Log.d(TAG, "RASP protection enabled successfully")
            } else {
                Log.w(TAG, "Integrity checks failed, protection not enabled")
            }
            
            checksPass
        } catch (e: Exception) {
            Log.e(TAG, "Error enabling protection", e)
            false
        }
    }

    /**
     * Performs comprehensive integrity checks
     */
    private fun performIntegrityChecks(): Boolean {
        return validateAPKSignature() &&
                validatePackageName() &&
                checkDynamicLibraryTampering() &&
                validateApplicationPath() &&
                checkForHooks()
    }

    /**
     * Validates APK signature against expected hash
     */
    private fun validateAPKSignature(): Boolean {
        return try {
            val packageInfo = context.packageManager.getPackageInfo(
                context.packageName,
                PackageManager.GET_SIGNATURES
            )
            
            val signature = packageInfo.signatures?.get(0) ?: return false
            val signatureHash = computeSignatureHash(signature)
            
            val isValid = signatureHash == EXPECTED_SIGNATURE_HASH
            protectionChecks["signature"] = isValid
            
            if (!isValid) {
                Log.w(TAG, "Invalid APK signature detected")
            }
            
            isValid
        } catch (e: Exception) {
            Log.e(TAG, "Error validating APK signature", e)
            false
        }
    }

    /**
     * Computes SHA-256 hash of the signature
     */
    private fun computeSignatureHash(signature: Signature): String {
        return try {
            val cert = signature.toByteArray()
            val input = ByteArrayInputStream(cert)
            val cf = CertificateFactory.getInstance("X509")
            val c = cf.generateCertificate(input) as X509Certificate
            
            val md = MessageDigest.getInstance("SHA256")
            val publicKey = md.digest(c.encoded)
            bytesToHex(publicKey)
        } catch (e: Exception) {
            Log.e(TAG, "Error computing signature hash", e)
            ""
        }
    }

    /**
     * Validates package name hasn't been tampered with
     */
    private fun validatePackageName(): Boolean {
        val currentPackage = context.packageName
        val isValid = currentPackage == EXPECTED_PACKAGE_NAME
        protectionChecks["package_name"] = isValid
        
        if (!isValid) {
            Log.w(TAG, "Package name mismatch: expected $EXPECTED_PACKAGE_NAME, got $currentPackage")
        }
        
        return isValid
    }

    /**
     * Checks for dynamic library tampering
     */
    private fun checkDynamicLibraryTampering(): Boolean {
        return try {
            // Check if native libraries are loaded from expected locations
            val applicationInfo = context.applicationInfo
            val nativeLibraryDir = applicationInfo.nativeLibraryDir
            
            // Verify the native library directory path
            val expectedPath = "/data/app/"
            val isValid = nativeLibraryDir?.startsWith(expectedPath) == true
            
            protectionChecks["native_libs"] = isValid
            
            if (!isValid) {
                Log.w(TAG, "Suspicious native library path: $nativeLibraryDir")
            }
            
            isValid
        } catch (e: Exception) {
            Log.e(TAG, "Error checking native libraries", e)
            false
        }
    }

    /**
     * Validates application installation path
     */
    private fun validateApplicationPath(): Boolean {
        return try {
            val sourceDir = context.applicationInfo.sourceDir
            
            // APK should be in /data/app/ for normal installations
            val isValid = sourceDir.startsWith("/data/app/") || 
                         sourceDir.startsWith("/system/app/") // System apps
            
            protectionChecks["app_path"] = isValid
            
            if (!isValid) {
                Log.w(TAG, "Suspicious app installation path: $sourceDir")
            }
            
            isValid
        } catch (e: Exception) {
            Log.e(TAG, "Error validating app path", e)
            false
        }
    }

    /**
     * Checks for common hooking frameworks
     */
    private fun checkForHooks(): Boolean {
        return try {
            val suspiciousClasses = arrayOf(
                "de.robv.android.xposed.XposedBridge",
                "de.robv.android.xposed.XposedHelpers",
                "com.saurik.substrate.MS",
                "com.android.internal.os.ZygoteInit"
            )
            
            for (className in suspiciousClasses) {
                try {
                    Class.forName(className)
                    Log.w(TAG, "Suspicious class detected: $className")
                    protectionChecks["hooks"] = false
                    return false
                } catch (e: ClassNotFoundException) {
                    // Expected - class not found is good
                }
            }
            
            protectionChecks["hooks"] = true
            true
        } catch (e: Exception) {
            Log.e(TAG, "Error checking for hooks", e)
            false
        }
    }

    /**
     * Enables continuous runtime protection
     */
    private fun enableContinuousProtection() {
        // Start periodic integrity checks
        Timer().scheduleAtFixedRate(object : TimerTask() {
            override fun run() {
                performRuntimeChecks()
            }
        }, 30000, 60000) // Check every minute after 30 seconds
    }

    /**
     * Performs runtime security checks
     */
    private fun performRuntimeChecks() {
        if (!isProtectionEnabled) return
        
        try {
            // Check for debugging
            if (Debug.isDebuggerConnected()) {
                Log.w(TAG, "Debugger detected during runtime")
                handleSecurityViolation("debugger_detected")
                return
            }
            
            // Check execution timing for anti-debugging
            val executionTime = measureTimeMillis {
                // Perform a simple operation
                Thread.sleep(1)
            }
            
            if (executionTime > MAX_EXECUTION_TIME) {
                Log.w(TAG, "Execution timing anomaly detected: ${executionTime}ms")
                handleSecurityViolation("timing_anomaly")
                return
            }
            
            // Validate integrity checksums
            if (!validateRuntimeIntegrity()) {
                Log.w(TAG, "Runtime integrity check failed")
                handleSecurityViolation("integrity_violation")
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "Error during runtime checks", e)
        }
    }

    /**
     * Validates runtime integrity
     */
    private fun validateRuntimeIntegrity(): Boolean {
        return try {
            // Re-check critical protections
            validatePackageName() && checkForHooks()
        } catch (e: Exception) {
            Log.e(TAG, "Error validating runtime integrity", e)
            false
        }
    }

    /**
     * Handles security violations
     */
    private fun handleSecurityViolation(violationType: String) {
        Log.w(TAG, "Security violation detected: $violationType")
        
        // Escalate security response based on violation type
        when (violationType) {
            "debugger_detected" -> {
                // Immediate response to debugging
                enableAntiDebugMeasures()
                clearSensitiveData()
            }
            "integrity_violation" -> {
                // Code tampering detected
                enableTamperResponse()
                reportTamperAttempt()
            }
            "timing_anomaly" -> {
                // Possible analysis tool detected
                enableAntiAnalysisMeasures()
            }
        }
        
        // Always report the violation
        reportSecurityViolation(violationType)
    }
    
    /**
     * Enable anti-debugging countermeasures
     */
    private fun enableAntiDebugMeasures() {
        try {
            // Terminate debugging session
            if (Debug.isDebuggerConnected()) {
                Log.w(TAG, "Terminating debug session")
                // Force app to background or close
                android.os.Process.killProcess(android.os.Process.myPid())
            }
            
            // Enable additional protections
            protectionChecks["anti_debug_active"] = true
            
        } catch (e: Exception) {
            Log.e(TAG, "Error enabling anti-debug measures", e)
        }
    }
    
    /**
     * Clear sensitive data when tampering is detected
     */
    private fun clearSensitiveData() {
        try {
            // Clear sensitive shared preferences
            val prefs = context.getSharedPreferences("sensitive_data", Context.MODE_PRIVATE)
            prefs.edit().clear().apply()
            
            // Clear cached data
            val cacheDir = context.cacheDir
            cacheDir.deleteRecursively()
            
            protectionChecks["data_cleared"] = true
            Log.i(TAG, "Sensitive data cleared due to security violation")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error clearing sensitive data", e)
        }
    }
    
    /**
     * Enable tamper response measures
     */
    private fun enableTamperResponse() {
        try {
            // Activate stealth mode
            enableStealthMode()
            
            // Disable non-essential functionality
            disableNonEssentialFeatures()
            
            protectionChecks["tamper_response_active"] = true
            
        } catch (e: Exception) {
            Log.e(TAG, "Error enabling tamper response", e)
        }
    }
    
    /**
     * Report tamper attempt
     */
    private fun reportTamperAttempt() {
        try {
            // Queue tamper report for transmission
            val prefs = context.getSharedPreferences("security_reports", Context.MODE_PRIVATE)
            val timestamp = System.currentTimeMillis()
            val reportKey = "tamper_attempt_$timestamp"
            
            val report = mapOf(
                "type" to "tamper_attempt",
                "timestamp" to timestamp,
                "device_info" to getDeviceFingerprint(),
                "app_state" to getAppState()
            )
            
            prefs.edit().putString(reportKey, report.toString()).apply()
            
        } catch (e: Exception) {
            Log.e(TAG, "Error reporting tamper attempt", e)
        }
    }
    
    /**
     * Enable anti-analysis measures
     */
    private fun enableAntiAnalysisMeasures() {
        try {
            // Randomize execution timing
            val randomDelay = (Math.random() * 100).toLong()
            Thread.sleep(randomDelay)
            
            // Add noise to function calls
            addExecutionNoise()
            
            protectionChecks["anti_analysis_active"] = true
            
        } catch (e: Exception) {
            Log.e(TAG, "Error enabling anti-analysis measures", e)
        }
    }
    
    /**
     * Enable stealth mode
     */
    private fun enableStealthMode() {
        try {
            // Hide app icon (requires additional implementation)
            // Reduce logging
            // Minimize network activity
            
            protectionChecks["stealth_mode"] = true
            Log.i(TAG, "Stealth mode activated")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error enabling stealth mode", e)
        }
    }
    
    /**
     * Disable non-essential features during security incident
     */
    private fun disableNonEssentialFeatures() {
        try {
            // Mark features as disabled
            protectionChecks["limited_functionality"] = true
            
            // Store in shared preferences for other components
            val prefs = context.getSharedPreferences("app_state", Context.MODE_PRIVATE)
            prefs.edit().putBoolean("security_mode", true).apply()
            
        } catch (e: Exception) {
            Log.e(TAG, "Error disabling features", e)
        }
    }
    
    /**
     * Add execution noise to confuse timing analysis
     */
    private fun addExecutionNoise() {
        try {
            // Random operations to confuse timing analysis
            val noise = mutableListOf<Int>()
            repeat((Math.random() * 10).toInt()) {
                noise.add(it * 2)
            }
            noise.sort()
            noise.clear()
            
        } catch (e: Exception) {
            // Intentionally catch and ignore
        }
    }
    
    /**
     * Get device fingerprint for security reporting
     */
    private fun getDeviceFingerprint(): Map<String, Any> {
        return try {
            mapOf(
                "build_fingerprint" to android.os.Build.FINGERPRINT,
                "build_model" to android.os.Build.MODEL,
                "build_manufacturer" to android.os.Build.MANUFACTURER,
                "app_signature" to (context.packageManager.getPackageInfo(
                    context.packageName,
                    PackageManager.GET_SIGNATURES
                ).signatures?.get(0)?.let { computeSignatureHash(it) } ?: "unavailable")
            )
        } catch (e: Exception) {
            mapOf("error" to "fingerprint_failed")
        }
    }
    
    /**
     * Get current app state
     */
    private fun getAppState(): Map<String, Any> {
        return mapOf(
            "protection_enabled" to isProtectionEnabled,
            "checks_status" to protectionChecks.toMap(),
            "memory_usage" to Runtime.getRuntime().totalMemory(),
            "process_id" to android.os.Process.myPid()
        )
    }
    
    /**
     * Report security violation to monitoring system
     */
    private fun reportSecurityViolation(violationType: String) {
        try {
            // Queue security violation for transmission
            val prefs = context.getSharedPreferences("security_violations", Context.MODE_PRIVATE)
            val timestamp = System.currentTimeMillis()
            val violationKey = "violation_$timestamp"
            
            val violation = mapOf(
                "type" to violationType,
                "timestamp" to timestamp,
                "severity" to "high",
                "response_actions" to getResponseActions(violationType)
            )
            
            prefs.edit().putString(violationKey, violation.toString()).apply()
            
        } catch (e: Exception) {
            Log.e(TAG, "Error reporting security violation", e)
        }
    }
    
    /**
     * Get response actions taken for violation type
     */
    private fun getResponseActions(violationType: String): List<String> {
        val actions = mutableListOf<String>()
        
        when (violationType) {
            "debugger_detected" -> {
                actions.add("anti_debug_enabled")
                actions.add("sensitive_data_cleared")
            }
            "integrity_violation" -> {
                actions.add("tamper_response_enabled")
                actions.add("stealth_mode_activated")
            }
            "timing_anomaly" -> {
                actions.add("anti_analysis_enabled")
                actions.add("execution_noise_added")
            }
        }
        
        return actions
    }

    /**
     * Returns current protection status
     */
    fun getProtectionStatus(): Map<String, Any> {
        return mapOf(
            "enabled" to isProtectionEnabled,
            "checks" to protectionChecks.toMap(),
            "timestamp" to System.currentTimeMillis()
        )
    }

    /**
     * Utility function to convert bytes to hex string
     */
    private fun bytesToHex(bytes: ByteArray): String {
        val result = StringBuilder()
        for (byte in bytes) {
            result.append(String.format("%02x", byte))
        }
        return result.toString()
    }
}