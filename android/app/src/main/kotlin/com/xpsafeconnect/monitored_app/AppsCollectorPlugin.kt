package com.xpsafeconnect.monitored_app

import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.os.Build
import android.os.Process
import android.provider.Settings
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.*

class AppsCollectorPlugin: FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.xpsafeconnect.monitored_app/apps")
        context = flutterPluginBinding.applicationContext
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "checkUsageStatsPermissions" -> {
                result.success(checkUsageStatsPermissions())
            }
            "requestUsageStatsPermissions" -> {
                requestUsageStatsPermissions()
                result.success(true)
            }
            "getInstalledApps" -> {
                val apps = getInstalledApps()
                result.success(apps)
            }
            "getAppUsage" -> {
                val timestamp = call.argument<Long>("since") ?: 0
                val usage = getAppUsage(timestamp)
                result.success(usage)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun checkUsageStatsPermissions(): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    Process.myUid(),
                    context.packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    Process.myUid(),
                    context.packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun requestUsageStatsPermissions() {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        context.startActivity(intent)
    }

    private fun getInstalledApps(): List<Map<String, Any>> {
        val result = ArrayList<Map<String, Any>>()
        val packageManager = context.packageManager

        val packages = packageManager.getInstalledPackages(0)
        for (packageInfo in packages) {
            val isSystemApp = packageInfo.applicationInfo.flags and ApplicationInfo.FLAG_SYSTEM != 0
            
            val appInfo = mapOf(
                    "package_name" to packageInfo.packageName,
                    "app_name" to (packageManager.getApplicationLabel(packageInfo.applicationInfo).toString()),
                    "version_name" to (packageInfo.versionName ?: ""),
                    "version_code" to packageInfo.longVersionCode,
                    "first_install_time" to packageInfo.firstInstallTime,
                    "last_update_time" to packageInfo.lastUpdateTime,
                    "is_system_app" to isSystemApp,
                    "category" to (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        packageManager.getApplicationInfo(packageInfo.packageName, 0).category.toString()
                    } else {
                        ""
                    })
            )
            result.add(appInfo)
        }

        return result
    }

    private fun getAppUsage(since: Long): List<Map<String, Any>> {
        val result = ArrayList<Map<String, Any>>()
        if (!checkUsageStatsPermissions()) {
            return result
        }

        val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val endTime = System.currentTimeMillis()
        val packageManager = context.packageManager

        // Get usage events
        val usageEvents = usageStatsManager.queryEvents(since, endTime)
        val event = UsageEvents.Event()
        
        // Track app usage sessions
        val sessions = mutableMapOf<String, MutableMap<String, Any>>()
        
        while (usageEvents.hasNextEvent()) {
            usageEvents.getNextEvent(event)
            
            // Track only foreground events
            if (event.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND || 
                event.eventType == UsageEvents.Event.MOVE_TO_BACKGROUND) {
                
                val packageName = event.packageName
                
                // Skip system packages
                if (packageName.startsWith("android") || 
                    packageName.startsWith("com.google.android") ||
                    packageName.startsWith("com.android")) {
                    continue
                }
                
                // Start of session
                if (event.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND) {
                    sessions[packageName] = mutableMapOf(
                            "package_name" to packageName,
                            "start_time" to event.timeStamp
                    )
                }
                // End of session
                else if (event.eventType == UsageEvents.Event.MOVE_TO_BACKGROUND && sessions.containsKey(packageName)) {
                    val session = sessions[packageName]!!
                    val startTime = session["start_time"] as Long
                    val endTime = event.timeStamp
                    val durationSeconds = (endTime - startTime) / 1000
                    
                    // Only record sessions longer than 1 second
                    if (durationSeconds > 1) {
                        try {
                            val appInfo = packageManager.getApplicationInfo(packageName, 0)
                            val appName = packageManager.getApplicationLabel(appInfo).toString()
                            
                            result.add(mapOf(
                                    "package_name" to packageName,
                                    "app_name" to appName,
                                    "start_time" to startTime,
                                    "end_time" to endTime,
                                    "duration" to durationSeconds
                            ))
                        } catch (e: PackageManager.NameNotFoundException) {
                            // Skip packages that can't be resolved
                        }
                    }
                    
                    // Remove the session
                    sessions.remove(packageName)
                }
            }
        }
        
        return result
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}