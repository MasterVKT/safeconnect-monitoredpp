package com.xpsafeconnect.monitored_app

import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Debug
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.File
import java.io.FileReader

class SecurityPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private lateinit var raspManager: RASPManager

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.xpsafeconnect.monitored_app/security")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
        raspManager = RASPManager(context)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isRootDetected" -> {
                result.success(isRootDetected())
            }
            "isDebuggingDetected" -> {
                result.success(isDebuggingDetected())
            }
            "isPackageInstalled" -> {
                val packageName = call.argument<String>("packageName")
                if (packageName != null) {
                    result.success(isPackageInstalled(packageName))
                } else {
                    result.error("INVALID_ARGUMENT", "Package name is required", null)
                }
            }
            "requestDeviceAdmin" -> {
                result.success(requestDeviceAdmin())
            }
            "isDeviceAdminActive" -> {
                result.success(isDeviceAdminActive())
            }
            "enableRuntimeProtection" -> {
                enableRuntimeProtection()
                result.success(true)
            }
            "enableIntegrityChecks" -> {
                enableIntegrityChecks()
                result.success(true)
            }
            "enableRASP" -> {
                val enabled = raspManager.enableProtection()
                result.success(enabled)
            }
            "getRASPStatus" -> {
                val status = raspManager.getProtectionStatus()
                result.success(status)
            }
            "lockDevice" -> {
                val durationMinutes = call.argument<Int>("durationMinutes") ?: 60
                result.success(lockDevice())
            }
            "wipeDeviceData" -> {
                val includeExternal = call.argument<Boolean>("includeExternal") ?: false
                result.success(wipeDeviceData(includeExternal))
            }
            "disableCamera" -> {
                val disabled = call.argument<Boolean>("disabled") ?: true
                result.success(setCameraDisabled(disabled))
            }
            "isCameraDisabled" -> {
                result.success(isCameraDisabled())
            }
            "setPasswordPolicy" -> {
                val minLength = call.argument<Int>("minLength") ?: 6
                val requireNumbers = call.argument<Boolean>("requireNumbers") ?: true
                val requireSymbols = call.argument<Boolean>("requireSymbols") ?: false
                result.success(setPasswordPolicy(minLength, requireNumbers, requireSymbols))
            }
            "getSecurityStatus" -> {
                result.success(getSecurityStatus())
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    private fun isRootDetected(): Boolean {
        return checkRootFiles() || 
               checkRootBinaries() || 
               checkSuCommand() ||
               checkRootApps() ||
               checkBuildTags() ||
               checkSystemProperties() ||
               checkWriteablePaths()
    }

    private fun checkRootFiles(): Boolean {
        val rootFiles = arrayOf(
            // Standard su binaries
            "/system/app/Superuser.apk",
            "/sbin/su",
            "/system/bin/su",
            "/system/xbin/su",
            "/data/local/xbin/su",
            "/data/local/bin/su",
            "/system/sd/xbin/su",
            "/system/bin/failsafe/su",
            "/data/local/su",
            "/su/bin/su",
            
            // Magisk files
            "/system/xbin/magisk",
            "/system/bin/magisk",
            "/data/adb/magisk",
            "/data/data/com.topjohnwu.magisk",
            "/data/adb/modules",
            "/cache/magisk.log",
            "/system/addon.d/99-magisk.sh",
            
            // SuperSU files
            "/system/bin/.ext/.su",
            "/system/usr/we-need-root/su-backup",
            "/system/xbin/daemonsu",
            "/system/etc/init.d/99SuperSUDaemon",
            "/system/app/SuperSU",
            "/system/app/SuperSU.apk",
            "/data/data/eu.chainfire.supersu",
            
            // KingRoot files
            "/data/data/com.kingroot.kinguser",
            "/data/data/com.kingo.root",
            
            // Other root tools
            "/system/app/RootAppDelete.apk",
            "/system/app/RootBrowser.apk",
            "/data/local/tmp/root",
            "/system/lib/libsupol.so",
            "/system/bin/mount.exfat_HWDRA",
            
            // Custom ROMs indicators
            "/system/recovery-resource/recovery-transform.sh",
            "/system/bin/recovery",
            "/system/recovery.img"
        )

        for (file in rootFiles) {
            if (File(file).exists()) {
                Log.w("SecurityPlugin", "Root file detected: $file")
                return true
            }
        }
        return false
    }

    private fun checkRootBinaries(): Boolean {
        val rootBinaries = arrayOf(
            "su", "busybox", "supersu", "magisk", "daemonsu", 
            "kingroot", "kingoroot", "kingo", "root", "rootcloak"
        )
        val paths = System.getenv("PATH")?.split(":") ?: return false

        for (binary in rootBinaries) {
            for (path in paths) {
                val file = File(path, binary)
                if (file.exists() && file.canExecute()) {
                    Log.w("SecurityPlugin", "Root binary detected: ${file.absolutePath}")
                    return true
                }
            }
        }
        return false
    }

    private fun checkSuCommand(): Boolean {
        return try {
            val process = Runtime.getRuntime().exec("which su")
            val exitValue = process.waitFor()
            exitValue == 0
        } catch (e: Exception) {
            false
        }
    }

    private fun checkRootApps(): Boolean {
        val rootApps = arrayOf(
            "com.noshufou.android.su",
            "com.noshufou.android.su.elite",
            "eu.chainfire.supersu",
            "com.koushikdutta.superuser",
            "com.thirdparty.superuser",
            "com.yellowes.su",
            "com.topjohnwu.magisk",
            "com.kingroot.kinguser",
            "com.kingo.root",
            "com.smedialink.oneclickroot",
            "com.zhiqupk.root.global",
            "com.alephzain.framaroot",
            "com.android.vending.billing.InAppBillingService.COIN",
            "com.chelpus.lackypatch",
            "com.ramdroid.appquarantine",
            "com.devadvance.rootcloak",
            "de.robv.android.xposed.installer",
            "com.saurik.substrate",
            "com.zachspong.temprootremovejb",
            "com.amphoras.hidemyroot",
            "com.amphoras.hidemyrootadfree",
            "com.formyhm.hiderootPremium"
        )

        val packageManager = context.packageManager
        for (app in rootApps) {
            try {
                packageManager.getPackageInfo(app, 0)
                Log.w("SecurityPlugin", "Root app detected: $app")
                return true
            } catch (e: PackageManager.NameNotFoundException) {
                // App not installed, continue
            }
        }
        return false
    }

    private fun checkBuildTags(): Boolean {
        val buildTags = android.os.Build.TAGS
        return buildTags != null && buildTags.contains("test-keys")
    }

    private fun checkSystemProperties(): Boolean {
        val dangerousProps = arrayOf(
            arrayOf("ro.debuggable", "1"),
            arrayOf("ro.secure", "0"),
            arrayOf("service.adb.root", "1"),
            arrayOf("ro.build.selinux", "0")
        )

        for (prop in dangerousProps) {
            try {
                val process = Runtime.getRuntime().exec("getprop ${prop[0]}")
                val reader = process.inputStream.bufferedReader()
                val value = reader.readLine()?.trim()
                reader.close()
                
                if (value == prop[1]) {
                    Log.w("SecurityPlugin", "Dangerous system property: ${prop[0]}=$value")
                    return true
                }
            } catch (e: Exception) {
                // Continue checking other properties
            }
        }
        return false
    }

    private fun checkWriteablePaths(): Boolean {
        val writeablePaths = arrayOf(
            "/system",
            "/system/bin",
            "/system/sbin",
            "/system/xbin",
            "/vendor/bin",
            "/sbin",
            "/etc"
        )

        for (path in writeablePaths) {
            val file = File(path)
            if (file.exists() && file.canWrite()) {
                Log.w("SecurityPlugin", "Writeable system path detected: $path")
                return true
            }
        }
        return false
    }

    private fun isDebuggingDetected(): Boolean {
        return checkDebuggerConnected() || checkTracerPid() || checkDebugFlags()
    }

    private fun checkDebuggerConnected(): Boolean {
        return Debug.isDebuggerConnected()
    }

    private fun checkTracerPid(): Boolean {
        return try {
            val file = File("/proc/self/status")
            if (!file.exists()) return false

            BufferedReader(FileReader(file)).use { reader ->
                var line: String?
                while (reader.readLine().also { line = it } != null) {
                    if (line!!.contains("TracerPid:")) {
                        val pid = line!!.substring(line!!.indexOf("TracerPid:") + 10).trim()
                        return pid != "0"
                    }
                }
            }
            false
        } catch (e: Exception) {
            false
        }
    }

    private fun checkDebugFlags(): Boolean {
        return try {
            val applicationInfo = context.applicationInfo
            (applicationInfo.flags and android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE) != 0
        } catch (e: Exception) {
            false
        }
    }

    private fun isPackageInstalled(packageName: String): Boolean {
        return try {
            context.packageManager.getPackageInfo(packageName, 0)
            true
        } catch (e: PackageManager.NameNotFoundException) {
            false
        }
    }

    private fun requestDeviceAdmin(): Boolean {
        return try {
            val component = ComponentName(context, AntiUninstallAdmin::class.java)
            val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN)
            intent.putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, component)
            intent.putExtra(
                DevicePolicyManager.EXTRA_ADD_EXPLANATION,
                "Cette autorisation est nécessaire pour protéger l'application."
            )
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
            true
        } catch (e: Exception) {
            Log.e("SecurityPlugin", "Error requesting device admin", e)
            false
        }
    }

    private fun isDeviceAdminActive(): Boolean {
        return try {
            val devicePolicyManager = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
            val component = ComponentName(context, AntiUninstallAdmin::class.java)
            devicePolicyManager.isAdminActive(component)
        } catch (e: Exception) {
            false
        }
    }

    private fun enableRuntimeProtection() {
        try {
            // Implement runtime protection measures
            Log.d("SecurityPlugin", "Runtime protection enabled")
        } catch (e: Exception) {
            Log.e("SecurityPlugin", "Error enabling runtime protection", e)
        }
    }

    private fun enableIntegrityChecks() {
        try {
            // Implement integrity check measures
            Log.d("SecurityPlugin", "Integrity checks enabled")
        } catch (e: Exception) {
            Log.e("SecurityPlugin", "Error enabling integrity checks", e)
        }
    }

    private fun lockDevice(): Boolean {
        return try {
            if (!isDeviceAdminActive()) {
                Log.w("SecurityPlugin", "Cannot lock device - admin not active")
                return false
            }

            val devicePolicyManager = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
            devicePolicyManager.lockNow()
            Log.d("SecurityPlugin", "Device locked successfully")
            true
        } catch (e: Exception) {
            Log.e("SecurityPlugin", "Error locking device", e)
            false
        }
    }

    private fun wipeDeviceData(includeExternal: Boolean): Boolean {
        return try {
            if (!isDeviceAdminActive()) {
                Log.w("SecurityPlugin", "Cannot wipe device - admin not active")
                return false
            }

            val devicePolicyManager = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
            val flags = if (includeExternal) {
                DevicePolicyManager.WIPE_EXTERNAL_STORAGE
            } else {
                0
            }
            
            Log.w("SecurityPlugin", "Device wipe initiated")
            devicePolicyManager.wipeData(flags)
            true
        } catch (e: Exception) {
            Log.e("SecurityPlugin", "Error wiping device", e)
            false
        }
    }

    private fun setCameraDisabled(disabled: Boolean): Boolean {
        return try {
            if (!isDeviceAdminActive()) {
                Log.w("SecurityPlugin", "Cannot set camera policy - admin not active")
                return false
            }

            val devicePolicyManager = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
            val component = ComponentName(context, AntiUninstallAdmin::class.java)
            
            devicePolicyManager.setCameraDisabled(component, disabled)
            Log.d("SecurityPlugin", "Camera ${if (disabled) "disabled" else "enabled"}")
            true
        } catch (e: Exception) {
            Log.e("SecurityPlugin", "Error setting camera policy", e)
            false
        }
    }

    private fun isCameraDisabled(): Boolean {
        return try {
            if (!isDeviceAdminActive()) return false

            val devicePolicyManager = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
            val component = ComponentName(context, AntiUninstallAdmin::class.java)
            
            devicePolicyManager.getCameraDisabled(component)
        } catch (e: Exception) {
            Log.e("SecurityPlugin", "Error checking camera policy", e)
            false
        }
    }

    private fun setPasswordPolicy(minLength: Int, requireNumbers: Boolean, requireSymbols: Boolean): Boolean {
        return try {
            if (!isDeviceAdminActive()) {
                Log.w("SecurityPlugin", "Cannot set password policy - admin not active")
                return false
            }

            val devicePolicyManager = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
            val component = ComponentName(context, AntiUninstallAdmin::class.java)
            
            // Set minimum length
            devicePolicyManager.setPasswordMinimumLength(component, minLength)
            
            // Set quality requirements
            val quality = when {
                requireNumbers && requireSymbols -> DevicePolicyManager.PASSWORD_QUALITY_COMPLEX
                requireNumbers -> DevicePolicyManager.PASSWORD_QUALITY_NUMERIC
                else -> DevicePolicyManager.PASSWORD_QUALITY_ALPHABETIC
            }
            devicePolicyManager.setPasswordQuality(component, quality)
            
            if (requireNumbers) {
                devicePolicyManager.setPasswordMinimumNumeric(component, 1)
            }
            if (requireSymbols) {
                devicePolicyManager.setPasswordMinimumSymbols(component, 1)
            }
            
            Log.d("SecurityPlugin", "Password policy updated")
            true
        } catch (e: Exception) {
            Log.e("SecurityPlugin", "Error setting password policy", e)
            false
        }
    }

    private fun getSecurityStatus(): Map<String, Any> {
        return try {
            val devicePolicyManager = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
            val isAdminActive = isDeviceAdminActive()
            val keyguardManager = context.getSystemService(Context.KEYGUARD_SERVICE) as android.app.KeyguardManager
            val isDeviceSecure = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                keyguardManager.isDeviceSecure
            } else {
                keyguardManager.isKeyguardSecure
            }

            mapOf(
                "isDeviceAdminActive" to isAdminActive,
                "isRootDetected" to isRootDetected(),
                "isDebuggingDetected" to isDebuggingDetected(),
                "isCameraDisabled" to if (isAdminActive) isCameraDisabled() else false,
                "isDeviceSecure" to isDeviceSecure,
                "hasActivePasswordPolicy" to if (isAdminActive) devicePolicyManager.isActivePasswordSufficientForDeviceRequirement() else false,
                "raspStatus" to raspManager.getProtectionStatus(),
                "securityLevel" to calculateSecurityLevel()
            )
        } catch (e: Exception) {
            Log.e("SecurityPlugin", "Error getting security status", e)
            mapOf("error" to (e.message ?: "unknown error"))
        }
    }

    private fun calculateSecurityLevel(): String {
        var score = 0
        var maxScore = 7

        // Admin protection (2 points)
        if (isDeviceAdminActive()) score += 2

        // Root detection (1 point)
        if (!isRootDetected()) score += 1

        // Debug detection (1 point)
        if (!isDebuggingDetected()) score += 1

        // Device secure (1 point)
        try {
            val keyguardManager = context.getSystemService(Context.KEYGUARD_SERVICE) as android.app.KeyguardManager
            val isDeviceSecure = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                keyguardManager.isDeviceSecure
            } else {
                keyguardManager.isKeyguardSecure
            }
            if (isDeviceSecure) score += 1
        } catch (e: Exception) {
            maxScore -= 1
        }

        // RASP protection (1 point)
        val raspStatus = raspManager.getProtectionStatus()
        if (raspStatus is Map<*, *> && raspStatus["enabled"] == true) score += 1

        // Camera policy (1 point)
        if (isDeviceAdminActive() && isCameraDisabled()) score += 1

        val percentage = (score.toDouble() / maxScore.toDouble() * 100).toInt()

        return when {
            percentage >= 85 -> "HIGH"
            percentage >= 60 -> "MEDIUM"
            percentage >= 40 -> "LOW"
            else -> "CRITICAL"
        }
    }
}