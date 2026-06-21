package com.xpsafeconnect.monitored_app

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Intent
import android.util.Log
import android.view.accessibility.AccessibilityEvent

class AccessibilityMonitoringService : AccessibilityService() {
    
    companion object {
        private const val TAG = "AccessibilityMonitoring"
        private var isServiceRunning = false
        
        fun isRunning(): Boolean = isServiceRunning
    }

    override fun onCreate() {
        super.onCreate()
        isServiceRunning = true
        Log.d(TAG, "Accessibility monitoring service created")
    }

    override fun onDestroy() {
        super.onDestroy()
        isServiceRunning = false
        Log.d(TAG, "Accessibility monitoring service destroyed")
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        
        val info = AccessibilityServiceInfo().apply {
            // Events we want to monitor
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or
                        AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED or
                        AccessibilityEvent.TYPE_VIEW_CLICKED or
                        AccessibilityEvent.TYPE_NOTIFICATION_STATE_CHANGED

            // Feedback type (no audio/haptic feedback)
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC

            // Flags for the service
            flags = AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS or
                   AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS or
                   AccessibilityServiceInfo.FLAG_REQUEST_ENHANCED_WEB_ACCESSIBILITY

            // Only monitor specific packages if needed (empty means all)
            packageNames = null

            // Delay before accessibility events are sent
            notificationTimeout = 100
        }
        
        serviceInfo = info
        isServiceRunning = true
        Log.d(TAG, "Accessibility monitoring service connected and configured")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        event?.let { accessibilityEvent ->
            try {
                when (accessibilityEvent.eventType) {
                    AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> {
                        handleWindowStateChanged(accessibilityEvent)
                    }
                    AccessibilityEvent.TYPE_NOTIFICATION_STATE_CHANGED -> {
                        handleNotificationChanged(accessibilityEvent)
                    }
                    AccessibilityEvent.TYPE_VIEW_CLICKED -> {
                        handleViewClicked(accessibilityEvent)
                    }
                    AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED -> {
                        handleWindowContentChanged(accessibilityEvent)
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error handling accessibility event: ${e.message}")
            }
        }
    }

    private fun handleWindowStateChanged(event: AccessibilityEvent) {
        val packageName = event.packageName?.toString() ?: return
        val className = event.className?.toString() ?: return
        
        Log.d(TAG, "Window state changed: $packageName - $className")
        
        // Track app usage - send to data collection service
        // This would integrate with the monitoring functionality
        notifyAppUsageChange(packageName, className, System.currentTimeMillis())
    }

    private fun handleNotificationChanged(event: AccessibilityEvent) {
        val packageName = event.packageName?.toString() ?: return
        val text = event.text?.joinToString(" ") ?: ""
        
        Log.d(TAG, "Notification from $packageName: $text")
        
        // Monitor notifications for messaging apps
        if (isMessagingApp(packageName)) {
            notifyMessagingActivity(packageName, text, System.currentTimeMillis())
        }
    }

    private fun handleViewClicked(event: AccessibilityEvent) {
        val packageName = event.packageName?.toString() ?: return
        val className = event.className?.toString() ?: return
        
        // Track user interactions
        Log.d(TAG, "View clicked in $packageName: $className")
    }

    private fun handleWindowContentChanged(event: AccessibilityEvent) {
        val packageName = event.packageName?.toString() ?: return
        
        // Monitor for specific app content changes
        if (isMonitoredApp(packageName)) {
            Log.d(TAG, "Content changed in monitored app: $packageName")
        }
    }

    private fun isMessagingApp(packageName: String): Boolean {
        val messagingApps = setOf(
            "com.whatsapp",
            "com.facebook.orca", // Messenger
            "org.telegram.messenger",
            "com.viber.voip",
            "com.snapchat.android",
            "com.instagram.android",
            "com.discord",
            "com.skype.raider"
        )
        return messagingApps.contains(packageName)
    }

    private fun isMonitoredApp(packageName: String): Boolean {
        // Add any specific apps that need special monitoring
        val monitoredApps = setOf(
            "com.android.mms", // SMS app
            "com.google.android.dialer", // Phone app
            "com.android.contacts"
        )
        return monitoredApps.contains(packageName)
    }

    private fun notifyAppUsageChange(packageName: String, className: String, timestamp: Long) {
        // Send app usage data to the monitoring service
        val intent = Intent("com.xpsafeconnect.monitored_app.APP_USAGE").apply {
            putExtra("package_name", packageName)
            putExtra("class_name", className)
            putExtra("timestamp", timestamp)
            setPackage(this@AccessibilityMonitoringService.packageName)
        }
        sendBroadcast(intent)
    }

    private fun notifyMessagingActivity(packageName: String, content: String, timestamp: Long) {
        // Send messaging activity to the monitoring service
        val intent = Intent("com.xpsafeconnect.monitored_app.MESSAGING_ACTIVITY").apply {
            putExtra("package_name", packageName)
            putExtra("content", content)
            putExtra("timestamp", timestamp)
            setPackage(this@AccessibilityMonitoringService.packageName)
        }
        sendBroadcast(intent)
    }

    override fun onInterrupt() {
        Log.w(TAG, "Accessibility service interrupted")
        isServiceRunning = false
    }

    override fun onUnbind(intent: Intent?): Boolean {
        Log.d(TAG, "Accessibility service unbound")
        isServiceRunning = false
        return super.onUnbind(intent)
    }
}