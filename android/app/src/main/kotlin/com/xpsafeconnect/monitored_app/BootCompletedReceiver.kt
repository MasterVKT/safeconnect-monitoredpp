package com.xpsafeconnect.monitored_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class BootCompletedReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            // Check if auto-start is enabled
            val sharedPreferences = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val autoStartEnabled = sharedPreferences.getBoolean("auto_start_enabled", true)
            val callbackHandle = sharedPreferences.getLong("callback_handle", 0)
            
            // Start service if auto-start is enabled and callback handle is available
            if (autoStartEnabled && callbackHandle != 0L) {
                BackgroundCollectorService.startService(context, callbackHandle)
            }
        }
    }
}