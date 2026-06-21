package com.xpsafeconnect.monitored_app

import android.app.Activity
import android.app.AppOpsManager
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.PowerManager
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class PermissionsPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var activity: Activity? = null

    companion object {
        private const val REQUEST_CODE_DEVICE_ADMIN = 1001
    }

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "monitored_app/permissions")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "checkPermission" -> {
                val permission = call.argument<String>("permission")
                if (permission != null) {
                    val status = checkCustomPermission(permission)
                    result.success(status)
                } else {
                    result.error("INVALID_ARGUMENT", "Permission parameter is required", null)
                }
            }
            "openSettings" -> {
                val settingsPath = call.argument<String>("settingsPath")
                if (settingsPath != null) {
                    try {
                        openSettingsScreen(settingsPath)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SETTINGS_ERROR", "Failed to open settings: ${e.message}", null)
                    }
                } else {
                    result.error("INVALID_ARGUMENT", "SettingsPath parameter is required", null)
                }
            }
            "requestPermission" -> {
                val permission = call.argument<String>("permission")
                val settingsPath = call.argument<String>("settingsPath")
                if (permission != null) {
                    try {
                        requestCustomPermission(permission, settingsPath)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("REQUEST_ERROR", "Failed to request permission: ${e.message}", null)
                    }
                } else {
                    result.error("INVALID_ARGUMENT", "Permission parameter is required", null)
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun checkCustomPermission(permission: String): String {
        return when (permission) {
            "accessibility_service" -> {
                if (isAccessibilityServiceEnabled()) "granted" else "denied"
            }
            "usage_stats" -> {
                if (hasUsageStatsPermission()) "granted" else "denied"
            }
            "device_admin" -> {
                if (isDeviceAdminActive()) "granted" else "denied"
            }
            "battery_optimization" -> {
                if (isBatteryOptimizationDisabled()) "granted" else "denied"
            }
            else -> "denied"
        }
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val am = context.getSystemService(Context.ACCESSIBILITY_SERVICE) as android.view.accessibility.AccessibilityManager
        val enabledServices = am.getEnabledAccessibilityServiceList(android.accessibilityservice.AccessibilityServiceInfo.FEEDBACK_ALL_MASK)
        for (service in enabledServices) {
            if (service.resolveInfo.serviceInfo.packageName == context.packageName) {
                return true
            }
        }
        return false
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOpsManager = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOpsManager.checkOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            android.os.Process.myUid(),
            context.packageName
        )
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun isDeviceAdminActive(): Boolean {
        val devicePolicyManager = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        val adminComponent = ComponentName(context, AntiUninstallAdmin::class.java)
        return devicePolicyManager.isAdminActive(adminComponent)
    }

    private fun isBatteryOptimizationDisabled(): Boolean {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
            val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            return powerManager.isIgnoringBatteryOptimizations(context.packageName)
        }
        return true // Not applicable for older versions
    }

    private fun openSettingsScreen(settingsPath: String) {
        val intent = when (settingsPath) {
            "android.settings.ACCESSIBILITY_SETTINGS" -> {
                Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
            }
            "android.settings.USAGE_ACCESS_SETTINGS" -> {
                Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
            }
            "android.settings.SECURITY_SETTINGS" -> {
                Intent(Settings.ACTION_SECURITY_SETTINGS)
            }
            "android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS" -> {
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                    Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                } else {
                    Intent(Settings.ACTION_SETTINGS)
                }
            }
            "android.settings.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS" -> {
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                    Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                        data = android.net.Uri.parse("package:${context.packageName}")
                    }
                } else {
                    Intent(Settings.ACTION_SETTINGS)
                }
            }
            else -> {
                Intent(Settings.ACTION_SETTINGS)
            }
        }
        
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
    }

    private fun requestCustomPermission(permission: String, settingsPath: String?) {
        when (permission) {
            "device_admin" -> openDeviceAdminRequest()
            "battery_optimization" -> openBatteryOptimizationRequest()
            else -> openSettingsScreen(settingsPath ?: "android.settings.SETTINGS")
        }
    }

    private fun openDeviceAdminRequest() {
        val currentActivity = activity
        if (currentActivity == null) {
            // Fallback sur applicationContext si l'Activity n'est pas disponible
            val adminComponent = ComponentName(context, AntiUninstallAdmin::class.java)
            val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN).apply {
                putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, adminComponent)
                putExtra(
                    DevicePolicyManager.EXTRA_ADD_EXPLANATION,
                    "XP SafeConnect needs this protection to keep monitoring features active."
                )
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
            return
        }

        val adminComponent = ComponentName(currentActivity, AntiUninstallAdmin::class.java)
        val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN).apply {
            putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, adminComponent)
            putExtra(
                DevicePolicyManager.EXTRA_ADD_EXPLANATION,
                "XP SafeConnect needs this protection to keep monitoring features active."
            )
        }
        // startActivityForResult permet a l'Activity de rester en premier plan
        // apres que l'utilisateur ait accepte/refuse la demande d'admin.
        currentActivity.startActivityForResult(intent, REQUEST_CODE_DEVICE_ADMIN)
    }

    private fun openBatteryOptimizationRequest() {
        val intent = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
            Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                data = android.net.Uri.parse("package:${context.packageName}")
            }
        } else {
            Intent(Settings.ACTION_SETTINGS)
        }

        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    // --- ActivityAware callbacks ---

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }
}
