package com.xpsafeconnect.monitored_app

import android.app.KeyguardManager
import android.content.Context
import android.os.Build
import android.os.PowerManager
import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class UnlockDevicePlugin: FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.xpsafeconnect.monitored_app/unlock")
        context = flutterPluginBinding.applicationContext
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "unlockDevice" -> {
                result.success(unlockDevice())
            }
            "isUnlockAvailable" -> {
                result.success(isUnlockAvailable())
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun unlockDevice(): Boolean {
        try {
            val keyguardManager = context.getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
            val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager

            // Wake up screen if it's off
            if (!powerManager.isInteractive) {
                val wakeLock = powerManager.newWakeLock(
                    PowerManager.FULL_WAKE_LOCK or
                    PowerManager.ACQUIRE_CAUSES_WAKEUP or
                    PowerManager.ON_AFTER_RELEASE, "safeconnect:unlockDeviceWakeLock"
                )
                wakeLock.acquire(10000) // 10 seconds
                wakeLock.release()
            }

            // Try to unlock keyguard
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                if (keyguardManager.isKeyguardLocked) {
                    val keyguardLock = keyguardManager.newKeyguardLock("safeconnect:keyguardLock")
                    keyguardLock.disableKeyguard()
                    return true
                }
            } else {
                @Suppress("DEPRECATION")
                val keyguardLock = keyguardManager.newKeyguardLock("safeconnect:keyguardLock")
                @Suppress("DEPRECATION")
                keyguardLock.disableKeyguard()
                return true
            }

            return !keyguardManager.isKeyguardLocked
        } catch (e: Exception) {
            e.printStackTrace()
            return false
        }
    }

    private fun isUnlockAvailable(): Boolean {
        return try {
            val keyguardManager = context.getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
            true
        } catch (e: Exception) {
            false
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}