package com.xpsafeconnect.monitored_app

import android.app.Activity
import android.app.ActivityManager
import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.os.Build
import android.view.WindowManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import android.util.Log

class StealthPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var context: Context? = null
    
    companion object {
        private const val TAG = "StealthPlugin"
        private const val CHANNEL = "com.xpsafeconnect.monitored_app/stealth"
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

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "applyStealthConfig" -> {
                applyStealthConfiguration(call, result)
            }
            "enableStealthMode" -> {
                enableStealthMode(result)
            }
            "disableStealthMode" -> {
                disableStealthMode(result)
            }
            "hideFromRecents" -> {
                hideFromRecents(result)
            }
            "disableScreenshots" -> {
                disableScreenshots(call, result)
            }
            "enableScreenshots" -> {
                enableScreenshots(result)
            }
            "setAppName" -> {
                setAppName(call, result)
            }
            "setAppIcon" -> {
                setAppIcon(call, result)
            }
            "isStealthModeActive" -> {
                isStealthModeActive(result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun applyStealthConfiguration(call: MethodCall, result: Result) {
        try {
            val config = call.arguments as? Map<String, Any>
            if (config == null) {
                result.error("INVALID_ARGUMENTS", "Configuration map is required", null)
                return
            }

            val mode = config["mode"] as? String ?: "none"
            val disguiseType = config["disguiseType"] as? String ?: "none"
            val hideFromRecents = config["hideFromRecents"] as? Boolean ?: false
            val hideNotifications = config["hideNotifications"] as? Boolean ?: false
            val disableScreenshots = config["disableScreenshots"] as? Boolean ?: false
            val customAppName = config["customAppName"] as? String

            Log.d(TAG, "Applying stealth configuration: mode=$mode, disguise=$disguiseType")

            // Apply screenshot protection
            if (disableScreenshots) {
                disableScreenshots(result = null)
            } else {
                enableScreenshots(result = null)
            }

            // Apply recent apps hiding
            if (hideFromRecents) {
                hideFromRecents(result = null)
            }

            // Store configuration preferences
            val prefs = context?.getSharedPreferences("stealth_config", Context.MODE_PRIVATE)
            prefs?.edit()?.apply {
                putString("stealth_mode", mode)
                putString("disguise_type", disguiseType)
                putBoolean("hide_from_recents", hideFromRecents)
                putBoolean("hide_notifications", hideNotifications)
                putBoolean("disable_screenshots", disableScreenshots)
                customAppName?.let { putString("custom_app_name", it) }
                apply()
            }

            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Error applying stealth configuration", e)
            result.error("STEALTH_CONFIG_ERROR", e.message, null)
        }
    }

    private fun enableStealthMode(result: Result) {
        try {
            Log.d(TAG, "Enabling stealth mode")
            
            // Set app to be hidden from recent apps
            hideFromRecents(result = null)
            
            // Disable screenshots
            disableScreenshots(result = null)
            
            // Store stealth state
            val prefs = context?.getSharedPreferences("stealth_config", Context.MODE_PRIVATE)
            prefs?.edit()?.putBoolean("stealth_active", true)?.apply()
            
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Error enabling stealth mode", e)
            result.error("STEALTH_ENABLE_ERROR", e.message, null)
        }
    }

    private fun disableStealthMode(result: Result) {
        try {
            Log.d(TAG, "Disabling stealth mode")
            
            // Re-enable screenshots
            enableScreenshots(result = null)
            
            // Clear stealth state
            val prefs = context?.getSharedPreferences("stealth_config", Context.MODE_PRIVATE)
            prefs?.edit()?.putBoolean("stealth_active", false)?.apply()
            
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Error disabling stealth mode", e)
            result.error("STEALTH_DISABLE_ERROR", e.message, null)
        }
    }

    private fun hideFromRecents(result: Result?) {
        try {
            activity?.let { activity ->
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                    // Set task description to hide or modify app in recents
                    val taskDescription = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                        ActivityManager.TaskDescription("System", null, 0)
                    } else {
                        @Suppress("DEPRECATION")
                        ActivityManager.TaskDescription("System", null, 0)
                    }
                    activity.setTaskDescription(taskDescription)
                }
                
                // Alternative approach: finish activity and restart as needed
                // This is more aggressive but effective
                activity.moveTaskToBack(true)
            }
            
            Log.d(TAG, "App hidden from recent apps")
            result?.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Error hiding from recents", e)
            result?.error("HIDE_RECENTS_ERROR", e.message, null)
        }
    }

    private fun disableScreenshots(call: MethodCall? = null, result: Result?) {
        try {
            activity?.let { activity ->
                activity.window.setFlags(
                    WindowManager.LayoutParams.FLAG_SECURE,
                    WindowManager.LayoutParams.FLAG_SECURE
                )
            }
            
            Log.d(TAG, "Screenshots disabled")
            result?.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Error disabling screenshots", e)
            result?.error("DISABLE_SCREENSHOTS_ERROR", e.message, null)
        }
    }

    private fun enableScreenshots(result: Result?) {
        try {
            activity?.let { activity ->
                activity.window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
            }
            
            Log.d(TAG, "Screenshots enabled")
            result?.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Error enabling screenshots", e)
            result?.error("ENABLE_SCREENSHOTS_ERROR", e.message, null)
        }
    }

    private fun setAppName(call: MethodCall, result: Result) {
        try {
            val appName = call.arguments as? String
            if (appName == null) {
                result.error("INVALID_ARGUMENTS", "App name is required", null)
                return
            }

            // Store the custom app name in preferences
            val prefs = context?.getSharedPreferences("stealth_config", Context.MODE_PRIVATE)
            prefs?.edit()?.putString("custom_app_name", appName)?.apply()
            
            Log.d(TAG, "App name set to: $appName")
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Error setting app name", e)
            result.error("SET_APP_NAME_ERROR", e.message, null)
        }
    }

    private fun setAppIcon(call: MethodCall, result: Result) {
        try {
            val iconName = call.arguments as? String
            if (iconName == null) {
                result.error("INVALID_ARGUMENTS", "Icon name is required", null)
                return
            }

            // Note: Changing app icon dynamically requires creating multiple
            // activity-alias entries in AndroidManifest.xml and enabling/disabling them
            // This is a complex implementation that would require manifest changes
            
            Log.d(TAG, "App icon change requested: $iconName (requires manifest configuration)")
            result.success(false) // Not implemented in this version
        } catch (e: Exception) {
            Log.e(TAG, "Error setting app icon", e)
            result.error("SET_APP_ICON_ERROR", e.message, null)
        }
    }

    private fun isStealthModeActive(result: Result) {
        try {
            val prefs = context?.getSharedPreferences("stealth_config", Context.MODE_PRIVATE)
            val isActive = prefs?.getBoolean("stealth_active", false) ?: false
            
            result.success(isActive)
        } catch (e: Exception) {
            Log.e(TAG, "Error checking stealth mode status", e)
            result.error("STEALTH_STATUS_ERROR", e.message, null)
        }
    }

    // Utility method to check if app is debuggable
    private fun isDebuggable(): Boolean {
        return try {
            context?.let { ctx ->
                val appInfo = ctx.packageManager.getApplicationInfo(ctx.packageName, 0)
                (appInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
            } ?: false
        } catch (e: Exception) {
            false
        }
    }

    // Utility method to get current app name
    private fun getCurrentAppName(): String {
        return try {
            context?.let { ctx ->
                val prefs = ctx.getSharedPreferences("stealth_config", Context.MODE_PRIVATE)
                val customName = prefs.getString("custom_app_name", null)
                
                if (customName != null) {
                    customName
                } else {
                    val appInfo = ctx.packageManager.getApplicationInfo(ctx.packageName, 0)
                    ctx.packageManager.getApplicationLabel(appInfo).toString()
                }
            } ?: "Unknown"
        } catch (e: Exception) {
            "Unknown"
        }
    }
}