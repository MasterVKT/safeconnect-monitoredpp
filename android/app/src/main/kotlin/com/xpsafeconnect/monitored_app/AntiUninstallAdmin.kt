package com.xpsafeconnect.monitored_app

import android.app.admin.DeviceAdminReceiver
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.util.Log
import android.widget.Toast
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class AntiUninstallAdmin : DeviceAdminReceiver() {
    private val TAG = "AntiUninstallAdmin"

    override fun onEnabled(context: Context, intent: Intent) {
        super.onEnabled(context, intent)
        Log.d(TAG, "Device admin enabled")
        
        // Log security event
        logSecurityEvent(context, "ADMIN_ENABLED", "Device admin protection activated")
        
        // Notify remote server
        notifyRemoteDevice(context, "admin_activated")
        
        // Show confirmation to user
        Toast.makeText(context, "Protection activée", Toast.LENGTH_SHORT).show()
        
        // Store admin state
        val prefs = context.getSharedPreferences("security_prefs", Context.MODE_PRIVATE)
        prefs.edit().putBoolean("admin_enabled", true).apply()
    }

    override fun onDisableRequested(context: Context, intent: Intent): CharSequence {
        Log.w(TAG, "Device admin disable requested")
        
        // Log security event
        logSecurityEvent(context, "ADMIN_DISABLE_REQUESTED", "Attempt to disable device admin protection")
        
        // Send alert to remote device
        sendAlert(context, "Tentative de désactivation de la protection détectée")
        
        // Return message to show to user
        return "Cette protection est nécessaire pour le bon fonctionnement de l'application. Contactez l'administrateur pour la désactiver."
    }

    override fun onDisabled(context: Context, intent: Intent) {
        super.onDisabled(context, intent)
        Log.w(TAG, "Device admin disabled")
        
        // Log security event
        logSecurityEvent(context, "ADMIN_DISABLED", "Device admin protection deactivated")
        
        // Emergency backup before losing admin privileges
        emergencyBackup(context)
        
        // Notify remote device
        notifyRemoteDevice(context, "admin_disabled")
        
        // Store admin state
        val prefs = context.getSharedPreferences("security_prefs", Context.MODE_PRIVATE)
        prefs.edit().putBoolean("admin_enabled", false).apply()
        
        // Try to reactivate admin (if possible)
        scheduleAdminReactivation(context)
    }

    override fun onPasswordChanged(context: Context, intent: Intent, user: android.os.UserHandle) {
        super.onPasswordChanged(context, intent, user)
        Log.d(TAG, "Device password changed")
        
        // Log security event
        logSecurityEvent(context, "PASSWORD_CHANGED", "Device password was changed")
    }

    override fun onPasswordFailed(context: Context, intent: Intent, user: android.os.UserHandle) {
        super.onPasswordFailed(context, intent, user)
        Log.w(TAG, "Device password failed")
        
        // Log security event
        logSecurityEvent(context, "PASSWORD_FAILED", "Failed password attempt detected")
    }

    companion object {
        const val ACTION_DEVICE_ADMIN_ENABLED = "com.xpsafeconnect.monitored_app.DEVICE_ADMIN_ENABLED"
        const val ACTION_DEVICE_ADMIN_DISABLED = "com.xpsafeconnect.monitored_app.DEVICE_ADMIN_DISABLED"

        fun getComponentName(context: Context): ComponentName {
            return ComponentName(context, AntiUninstallAdmin::class.java)
        }

        fun isAdminActive(context: Context): Boolean {
            val devicePolicyManager = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
            return devicePolicyManager.isAdminActive(getComponentName(context))
        }

        fun requestAdminPrivileges(context: Context): Intent {
            val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN)
            intent.putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, getComponentName(context))
            intent.putExtra(
                DevicePolicyManager.EXTRA_ADD_EXPLANATION,
                "Cette autorisation est nécessaire pour protéger l'application contre la désinstallation non autorisée."
            )
            return intent
        }

        fun disableAdmin(context: Context) {
            if (isAdminActive(context)) {
                val devicePolicyManager = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
                devicePolicyManager.removeActiveAdmin(getComponentName(context))
            }
        }
    }

    private fun logSecurityEvent(context: Context, eventType: String, description: String) {
        try {
            // This should integrate with the Flutter DatabaseService
            // For now, log to Android logs and shared preferences
            val prefs = context.getSharedPreferences("security_logs", Context.MODE_PRIVATE)
            val timestamp = System.currentTimeMillis()
            val logEntry = "$timestamp:$eventType:$description"
            
            // Store last 100 events
            val existingLogs = prefs.getStringSet("events", mutableSetOf()) ?: mutableSetOf()
            existingLogs.add(logEntry)
            
            // Keep only last 100 events
            if (existingLogs.size > 100) {
                val sortedLogs = existingLogs.sorted()
                existingLogs.clear()
                existingLogs.addAll(sortedLogs.takeLast(100))
            }
            
            prefs.edit().putStringSet("events", existingLogs).apply()
            
        } catch (e: Exception) {
            Log.e("AntiUninstallAdmin", "Error logging security event", e)
        }
    }

    private fun sendAlert(context: Context, message: String) {
        CoroutineScope(Dispatchers.IO).launch {
            try {
                // This should integrate with the WebSocket service or HTTP client
                // For now, store alert for later transmission
                val prefs = context.getSharedPreferences("pending_alerts", Context.MODE_PRIVATE)
                val timestamp = System.currentTimeMillis()
                val alertKey = "alert_$timestamp"
                
                prefs.edit().putString(alertKey, message).apply()
                
                Log.d("AntiUninstallAdmin", "Alert queued: $message")
                
            } catch (e: Exception) {
                Log.e("AntiUninstallAdmin", "Error sending alert", e)
            }
        }
    }

    private fun notifyRemoteDevice(context: Context, event: String) {
        CoroutineScope(Dispatchers.IO).launch {
            try {
                // Queue notification for transmission
                val prefs = context.getSharedPreferences("pending_notifications", Context.MODE_PRIVATE)
                val timestamp = System.currentTimeMillis()
                val notificationKey = "notification_$timestamp"
                
                val notification = mapOf(
                    "type" to "admin_event",
                    "event" to event,
                    "timestamp" to timestamp,
                    "device_id" to getDeviceId(context)
                )
                
                prefs.edit().putString(notificationKey, notification.toString()).apply()
                
                Log.d("AntiUninstallAdmin", "Remote notification queued: $event")
                
            } catch (e: Exception) {
                Log.e("AntiUninstallAdmin", "Error notifying remote device", e)
            }
        }
    }

    private fun emergencyBackup(context: Context) {
        CoroutineScope(Dispatchers.IO).launch {
            try {
                // Backup critical data before losing admin privileges
                val prefs = context.getSharedPreferences("emergency_backup", Context.MODE_PRIVATE)
                val timestamp = System.currentTimeMillis()
                
                prefs.edit()
                    .putLong("backup_timestamp", timestamp)
                    .putBoolean("admin_lost", true)
                    .putString("backup_reason", "admin_disabled")
                    .apply()
                
                Log.d("AntiUninstallAdmin", "Emergency backup completed")
                
            } catch (e: Exception) {
                Log.e("AntiUninstallAdmin", "Error during emergency backup", e)
            }
        }
    }

    private fun scheduleAdminReactivation(context: Context) {
        try {
            // Schedule a background task to try reactivating admin privileges
            val prefs = context.getSharedPreferences("admin_reactivation", Context.MODE_PRIVATE)
            prefs.edit()
                .putBoolean("reactivation_needed", true)
                .putLong("deactivation_timestamp", System.currentTimeMillis())
                .apply()
            
            Log.d("AntiUninstallAdmin", "Admin reactivation scheduled")
            
        } catch (e: Exception) {
            Log.e("AntiUninstallAdmin", "Error scheduling admin reactivation", e)
        }
    }

    private fun getDeviceId(context: Context): String {
        // This should use the same device ID generation as DeviceUtils
        val prefs = context.getSharedPreferences("device_info", Context.MODE_PRIVATE)
        return prefs.getString("device_id", "unknown") ?: "unknown"
    }
}