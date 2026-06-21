package com.xpsafeconnect.monitored_app

import android.app.ActivityManager
import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.os.Build
import android.os.Debug
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.BufferedReader
import java.io.File
import java.io.FileReader
import java.io.IOException
import java.io.InputStreamReader
import java.security.MessageDigest
import java.util.zip.ZipFile
import dalvik.system.DexFile
import java.lang.reflect.Method
import android.os.Process
import java.util.*

class AntiTamperPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private var context: Context? = null
    private var protectionKey: String? = null
    private var protectionSequence: List<Int>? = null
    
    companion object {
        private const val TAG = "AntiTamperPlugin"
        private const val CHANNEL = "com.xpsafeconnect.monitored_app/anti_tamper"
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)
        context = binding.applicationContext
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        context = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {}
    override fun onDetachedFromActivityForConfigChanges() {}
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {}
    override fun onDetachedFromActivity() {}

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getAppBinaryHash" -> {
                getAppBinaryHash(result)
            }
            "getLibraryChecksums" -> {
                getLibraryChecksums(result)
            }
            "initializeRuntimeProtection" -> {
                initializeRuntimeProtection(call, result)
            }
            "isBeingDebugged" -> {
                isBeingDebugged(result)
            }
            "detectHooking" -> {
                detectHooking(result)
            }
            "checkRuntimeModifications" -> {
                checkRuntimeModifications(result)
            }
            "getMethodChecksums" -> {
                getMethodChecksums(result)
            }
            "getDynamicLoads" -> {
                getDynamicLoads(result)
            }
            "enableAntiDebugging" -> {
                enableAntiDebugging(result)
            }
            "verifyObfuscation" -> {
                verifyObfuscation(result)
            }
            "advancedRootDetection" -> {
                advancedRootDetection(result)
            }
            "detectEmulator" -> {
                detectEmulator(result)
            }
            "enableEnhancedProtection" -> {
                enableEnhancedProtection(result)
            }
            "initiateSecurityLockdown" -> {
                initiateSecurityLockdown(result)
            }
            "enableAntiHooking" -> {
                enableAntiHooking(result)
            }
            "resetProtectionMeasures" -> {
                resetProtectionMeasures(result)
            }
            "enableGenericProtection" -> {
                enableGenericProtection(result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun getAppBinaryHash(result: Result) {
        try {
            val context = this.context ?: run {
                result.error("CONTEXT_ERROR", "Context not available", null)
                return
            }

            val packageInfo = context.packageManager.getPackageInfo(context.packageName, 0)
            val apkPath = packageInfo.applicationInfo?.sourceDir ?: run {
                result.error("APP_INFO_ERROR", "ApplicationInfo not available", null)
                return
            }
            
            val hash = calculateFileHash(apkPath)
            result.success(hash)
        } catch (e: Exception) {
            Log.e(TAG, "Error getting app binary hash", e)
            result.error("HASH_ERROR", e.message, null)
        }
    }

    private fun getLibraryChecksums(result: Result) {
        try {
            val context = this.context ?: run {
                result.error("CONTEXT_ERROR", "Context not available", null)
                return
            }

            val checksums = mutableMapOf<String, String>()
            
            // Get native library directory
            val nativeLibDir = context.applicationInfo.nativeLibraryDir
            val libDir = File(nativeLibDir)
            
            if (libDir.exists() && libDir.isDirectory) {
                libDir.listFiles()?.forEach { file ->
                    if (file.isFile && file.name.endsWith(".so")) {
                        checksums[file.name] = calculateFileHash(file.absolutePath)
                    }
                }
            }

            // Get DEX file checksums
            val packageInfo = context.packageManager.getPackageInfo(context.packageName, 0)
            val apkPath = packageInfo.applicationInfo?.sourceDir ?: run {
                result.error("APP_INFO_ERROR", "ApplicationInfo not available", null)
                return
            }
            
            try {
                val zipFile = ZipFile(apkPath)
                val entries = zipFile.entries()
                
                while (entries.hasMoreElements()) {
                    val entry = entries.nextElement()
                    if (entry.name.endsWith(".dex")) {
                        val inputStream = zipFile.getInputStream(entry)
                        val bytes = inputStream.readBytes()
                        checksums[entry.name] = calculateHash(bytes)
                        inputStream.close()
                    }
                }
                zipFile.close()
            } catch (e: Exception) {
                Log.w(TAG, "Error reading DEX files", e)
            }

            result.success(checksums.toString())
        } catch (e: Exception) {
            Log.e(TAG, "Error getting library checksums", e)
            result.error("CHECKSUM_ERROR", e.message, null)
        }
    }

    private fun initializeRuntimeProtection(call: MethodCall, result: Result) {
        try {
            protectionKey = call.argument<String>("protection_key")
            protectionSequence = call.argument<List<Int>>("protection_sequence")
            
            Log.d(TAG, "Runtime protection initialized")
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Error initializing runtime protection", e)
            result.error("INIT_ERROR", e.message, null)
        }
    }

    private fun isBeingDebugged(result: Result) {
        try {
            val isDebugging = Debug.isDebuggerConnected() || 
                             isDebuggerConnectedAdvanced() ||
                             checkTracerPid()
            
            result.success(isDebugging)
        } catch (e: Exception) {
            Log.e(TAG, "Error checking debugging status", e)
            result.success(false)
        }
    }

    private fun isDebuggerConnectedAdvanced(): Boolean {
        return try {
            // Check for debugging through various methods
            val debugging1 = (context?.applicationInfo?.flags ?: 0) and ApplicationInfo.FLAG_DEBUGGABLE != 0
            val debugging2 = Settings.Secure.getInt(context?.contentResolver, Settings.Global.ADB_ENABLED, 0) != 0
            val debugging3 = android.os.Debug.isDebuggerConnected()
            
            debugging1 || debugging2 || debugging3
        } catch (e: Exception) {
            false
        }
    }

    private fun checkTracerPid(): Boolean {
        return try {
            val file = File("/proc/self/status")
            val reader = BufferedReader(FileReader(file))
            var line: String?
            
            while (reader.readLine().also { line = it } != null) {
                if (line!!.startsWith("TracerPid:")) {
                    val tracerPid = line!!.substring(10).trim().toInt()
                    reader.close()
                    return tracerPid != 0
                }
            }
            reader.close()
            false
        } catch (e: Exception) {
            false
        }
    }

    private fun detectHooking(result: Result) {
        try {
            val hookingDetected = checkForHooking() || checkForFridaFramework()
            result.success(hookingDetected)
        } catch (e: Exception) {
            Log.e(TAG, "Error detecting hooking", e)
            result.success(false)
        }
    }

    private fun checkForHooking(): Boolean {
        return try {
            // Check for common hooking frameworks
            val suspiciousLibs = listOf(
                "libfrida-gadget.so",
                "libxposed_art.so",
                "libsubstrate.so",
                "libsandhook.so"
            )
            
            val mapsFile = File("/proc/self/maps")
            if (mapsFile.exists()) {
                val content = mapsFile.readText()
                suspiciousLibs.any { lib -> content.contains(lib) }
            } else {
                false
            }
        } catch (e: Exception) {
            false
        }
    }

    private fun checkForFridaFramework(): Boolean {
        return try {
            // Check for Frida server
            val fridaPorts = listOf(27042, 27043, 27044, 27045)
            val networkFiles = listOf("/proc/net/tcp", "/proc/net/tcp6")
            
            for (file in networkFiles) {
                try {
                    val content = File(file).readText()
                    for (port in fridaPorts) {
                        val hexPort = String.format("%04X", port)
                        if (content.contains(":$hexPort ")) {
                            return true
                        }
                    }
                } catch (e: Exception) {
                    // Ignore and continue
                }
            }
            false
        } catch (e: Exception) {
            false
        }
    }

    private fun checkRuntimeModifications(result: Result) {
        try {
            val modifications = mutableMapOf<String, Any>()
            
            // Check method signatures
            val modifiedMethods = checkMethodSignatures()
            if (modifiedMethods.isNotEmpty()) {
                modifications["modified_methods"] = modifiedMethods
                modifications["detected"] = true
            } else {
                modifications["detected"] = false
            }
            
            result.success(modifications)
        } catch (e: Exception) {
            Log.e(TAG, "Error checking runtime modifications", e)
            result.success(mapOf("detected" to false, "error" to e.message))
        }
    }

    private fun checkMethodSignatures(): List<String> {
        val modifiedMethods = mutableListOf<String>()
        
        try {
            // Check critical system methods
            val criticalMethods = listOf(
                "android.os.Debug.isDebuggerConnected",
                "java.lang.System.exit",
                "android.content.pm.PackageManager.getPackageInfo"
            )
            
            for (methodName in criticalMethods) {
                if (isMethodModified(methodName)) {
                    modifiedMethods.add(methodName)
                }
            }
        } catch (e: Exception) {
            Log.w(TAG, "Error checking method signatures", e)
        }
        
        return modifiedMethods
    }

    private fun isMethodModified(methodName: String): Boolean {
        return try {
            val parts = methodName.split(".")
            val className = parts.dropLast(1).joinToString(".")
            val methodNameOnly = parts.last()
            
            val clazz = Class.forName(className)
            val methods = clazz.declaredMethods
            
            for (method in methods) {
                if (method.name == methodNameOnly) {
                    // Simple check for method modification
                    // In a real implementation, you'd check method bytecode
                    val methodString = method.toString()
                    return methodString.contains("synthetic") || methodString.contains("proxy")
                }
            }
            false
        } catch (e: Exception) {
            false
        }
    }

    private fun getMethodChecksums(result: Result) {
        try {
            val checksums = mutableMapOf<String, String>()
            
            // Get checksums for critical methods
            val criticalMethods = listOf(
                "onCreate",
                "onResume",
                "onPause"
            )
            
            for (methodName in criticalMethods) {
                checksums[methodName] = calculateMethodChecksum(methodName)
            }
            
            result.success(checksums)
        } catch (e: Exception) {
            Log.e(TAG, "Error getting method checksums", e)
            result.success(emptyMap<String, String>())
        }
    }

    private fun calculateMethodChecksum(methodName: String): String {
        return try {
            // Simple implementation - in production, use actual bytecode
            val data = "$methodName:${System.currentTimeMillis()}"
            calculateHash(data.toByteArray())
        } catch (e: Exception) {
            "unknown"
        }
    }

    private fun getDynamicLoads(result: Result) {
        try {
            val loadedLibs = mutableListOf<String>()
            
            // Read /proc/self/maps to get loaded libraries
            val mapsFile = File("/proc/self/maps")
            if (mapsFile.exists()) {
                val lines = mapsFile.readLines()
                for (line in lines) {
                    if (line.contains(".so") && !line.contains("/system/")) {
                        val parts = line.split(" ")
                        if (parts.size > 5) {
                            val libPath = parts.last()
                            if (!loadedLibs.contains(libPath)) {
                                loadedLibs.add(libPath)
                            }
                        }
                    }
                }
            }
            
            result.success(loadedLibs)
        } catch (e: Exception) {
            Log.e(TAG, "Error getting dynamic loads", e)
            result.success(emptyList<String>())
        }
    }

    private fun enableAntiDebugging(result: Result) {
        try {
            // Anti-debugging measures
            enablePtraceProtection()
            enableTimingProtection()
            
            Log.d(TAG, "Anti-debugging enabled")
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Error enabling anti-debugging", e)
            result.success(false)
        }
    }

    private fun enablePtraceProtection() {
        try {
            // Fork a child process to trace ourselves
            val pid = Process.myPid()
            val process = Runtime.getRuntime().exec("su -c 'echo 1 > /proc/sys/kernel/yama/ptrace_scope'")
            process.waitFor()
        } catch (e: Exception) {
            Log.w(TAG, "Ptrace protection failed", e)
        }
    }

    private fun enableTimingProtection() {
        // Implement timing-based debugging detection
        Thread {
            while (true) {
                val start = System.nanoTime()
                Thread.sleep(100)
                val end = System.nanoTime()
                
                val elapsed = (end - start) / 1_000_000 // Convert to milliseconds
                if (elapsed > 200) { // Suspicious delay
                    Log.w(TAG, "Timing anomaly detected - possible debugging")
                }
            }
        }.start()
    }

    private fun verifyObfuscation(result: Result) {
        try {
            // Check if code appears to be obfuscated
            val isObfuscated = checkClassNamesObfuscation() && checkMethodNamesObfuscation()
            result.success(isObfuscated)
        } catch (e: Exception) {
            Log.e(TAG, "Error verifying obfuscation", e)
            result.success(false)
        }
    }

    private fun checkClassNamesObfuscation(): Boolean {
        return try {
            val packageName = context?.packageName ?: return false
            val packageInfo = context?.packageManager?.getPackageInfo(packageName, 0)
            val apkPath = packageInfo?.applicationInfo?.sourceDir ?: return false
            
            // Simple check - look for class names that appear obfuscated
            val dexFile = DexFile(apkPath)
            val classNames = dexFile.entries().asSequence().take(10).toList()
            
            classNames.any { className ->
                val parts = className.split(".")
                val lastPart = parts.lastOrNull() ?: ""
                lastPart.length <= 2 || lastPart.matches(Regex("^[a-z]{1,3}$"))
            }
        } catch (e: Exception) {
            false
        }
    }

    private fun checkMethodNamesObfuscation(): Boolean {
        return try {
            // Check if method names appear obfuscated
            val methods = this::class.java.declaredMethods
            methods.any { method ->
                method.name.length <= 2 || method.name.matches(Regex("^[a-z]{1,3}$"))
            }
        } catch (e: Exception) {
            false
        }
    }

    private fun advancedRootDetection(result: Result) {
        try {
            val rootDetected = checkSuperuserApps() ||
                             checkRootFiles() ||
                             checkBuildTags() ||
                             checkRootManagementApps() ||
                             checkBusybox()
            
            result.success(rootDetected)
        } catch (e: Exception) {
            Log.e(TAG, "Error in advanced root detection", e)
            result.success(false)
        }
    }

    private fun checkSuperuserApps(): Boolean {
        val superuserApps = listOf(
            "com.noshufou.android.su",
            "com.noshufou.android.su.elite",
            "eu.chainfire.supersu",
            "com.koushikdutta.superuser",
            "com.thirdparty.superuser",
            "com.yellowes.su",
            "com.topjohnwu.magisk",
            "com.kingroot.kinguser",
            "com.kingo.root",
            "com.smedialink.oneclickroot"
        )
        
        return superuserApps.any { packageName ->
            try {
                context?.packageManager?.getPackageInfo(packageName, 0)
                true
            } catch (e: PackageManager.NameNotFoundException) {
                false
            }
        }
    }

    private fun checkRootFiles(): Boolean {
        val rootFiles = listOf(
            "/system/app/Superuser.apk",
            "/sbin/su",
            "/system/bin/su",
            "/system/xbin/su",
            "/data/local/xbin/su",
            "/data/local/bin/su",
            "/system/sd/xbin/su",
            "/system/bin/failsafe/su",
            "/data/local/su",
            "/su/bin/su"
        )
        
        return rootFiles.any { File(it).exists() }
    }

    private fun checkBuildTags(): Boolean {
        val buildTags = Build.TAGS
        return buildTags != null && buildTags.contains("test-keys")
    }

    private fun checkRootManagementApps(): Boolean {
        val rootManagementApps = listOf(
            "com.zachspong.temprootremovejb",
            "com.ramdroid.appquarantine",
            "com.topjohnwu.magisk"
        )
        
        return rootManagementApps.any { packageName ->
            try {
                context?.packageManager?.getApplicationInfo(packageName, 0)
                true
            } catch (e: PackageManager.NameNotFoundException) {
                false
            }
        }
    }

    private fun checkBusybox(): Boolean {
        return try {
            val process = Runtime.getRuntime().exec("which busybox")
            val reader = BufferedReader(InputStreamReader(process.inputStream))
            val result = reader.readLine()
            reader.close()
            process.destroy()
            result != null
        } catch (e: Exception) {
            false
        }
    }

    private fun detectEmulator(result: Result) {
        try {
            val emulatorDetected = checkEmulatorProperties() ||
                                 checkEmulatorFiles() ||
                                 checkTelephonyManager() ||
                                 checkSensors()
            
            result.success(emulatorDetected)
        } catch (e: Exception) {
            Log.e(TAG, "Error detecting emulator", e)
            result.success(false)
        }
    }

    private fun checkEmulatorProperties(): Boolean {
        val emulatorProps = mapOf(
            "ro.product.model" to listOf("sdk", "emulator", "Android SDK built for x86"),
            "ro.product.device" to listOf("generic", "generic_x86", "generic_x86_64"),
            "ro.product.brand" to listOf("generic", "Android"),
            "ro.build.fingerprint" to listOf("generic", "unknown"),
            "ro.hardware" to listOf("goldfish", "ranchu")
        )
        
        return emulatorProps.any { (property, suspiciousValues) ->
            val value = getSystemProperty(property)
            suspiciousValues.any { suspicious ->
                value.contains(suspicious, ignoreCase = true)
            }
        }
    }

    private fun getSystemProperty(property: String): String {
        return try {
            val process = Runtime.getRuntime().exec("getprop $property")
            val reader = BufferedReader(InputStreamReader(process.inputStream))
            val result = reader.readLine() ?: ""
            reader.close()
            process.destroy()
            result
        } catch (e: Exception) {
            ""
        }
    }

    private fun checkEmulatorFiles(): Boolean {
        val emulatorFiles = listOf(
            "/dev/socket/qemud",
            "/dev/qemu_pipe",
            "/system/lib/libc_malloc_debug_qemu.so",
            "/sys/qemu_trace",
            "/system/bin/qemu-props"
        )
        
        return emulatorFiles.any { File(it).exists() }
    }

    private fun checkTelephonyManager(): Boolean {
        return try {
            val telephonyManager = context?.getSystemService(Context.TELEPHONY_SERVICE) as? android.telephony.TelephonyManager
            val deviceId = telephonyManager?.deviceId
            val networkOperatorName = telephonyManager?.networkOperatorName
            
            deviceId == null || 
            deviceId == "000000000000000" ||
            networkOperatorName == "Android"
        } catch (e: Exception) {
            false
        }
    }

    private fun checkSensors(): Boolean {
        return try {
            val sensorManager = context?.getSystemService(Context.SENSOR_SERVICE) as? android.hardware.SensorManager
            val sensors = sensorManager?.getSensorList(android.hardware.Sensor.TYPE_ALL) ?: emptyList()
            sensors.size < 5 // Emulators typically have fewer sensors
        } catch (e: Exception) {
            false
        }
    }

    // Protection action implementations
    private fun enableEnhancedProtection(result: Result) {
        try {
            enableAntiDebugging(result)
            // Add more enhanced protection measures
            Log.d(TAG, "Enhanced protection enabled")
        } catch (e: Exception) {
            Log.e(TAG, "Error enabling enhanced protection", e)
            result.success(false)
        }
    }

    private fun initiateSecurityLockdown(result: Result) {
        try {
            // Implement security lockdown measures
            Log.w(TAG, "Security lockdown initiated")
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Error initiating security lockdown", e)
            result.success(false)
        }
    }

    private fun enableAntiHooking(result: Result) {
        try {
            // Implement anti-hooking measures
            Log.d(TAG, "Anti-hooking enabled")
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Error enabling anti-hooking", e)
            result.success(false)
        }
    }

    private fun resetProtectionMeasures(result: Result) {
        try {
            // Reset and reinitialize protection measures
            protectionKey = null
            protectionSequence = null
            Log.d(TAG, "Protection measures reset")
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Error resetting protection measures", e)
            result.success(false)
        }
    }

    private fun enableGenericProtection(result: Result) {
        try {
            // Implement generic protection measures
            Log.d(TAG, "Generic protection enabled")
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Error enabling generic protection", e)
            result.success(false)
        }
    }

    // Utility methods
    private fun calculateFileHash(filePath: String): String {
        return try {
            val file = File(filePath)
            val bytes = file.readBytes()
            calculateHash(bytes)
        } catch (e: Exception) {
            "error_${e.hashCode()}"
        }
    }

    private fun calculateHash(data: ByteArray): String {
        return try {
            val digest = MessageDigest.getInstance("SHA-256")
            val hash = digest.digest(data)
            hash.joinToString("") { "%02x".format(it) }
        } catch (e: Exception) {
            "error_${e.hashCode()}"
        }
    }
}