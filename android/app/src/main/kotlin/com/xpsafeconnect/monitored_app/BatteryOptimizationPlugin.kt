package com.xpsafeconnect.monitored_app

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class BatteryOptimizationPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private var context: Context? = null

    companion object {
        private const val TAG = "BatteryOptPlugin"
        private const val CHANNEL = "com.xpsafeconnect.monitored_app/battery"
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        context = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "requestDisableBatteryOptimization" -> requestDisableBatteryOptimization(result)
            "isBatteryOptimizationDisabled" -> isBatteryOptimizationDisabled(result)
            else -> result.notImplemented()
        }
    }

    private fun requestDisableBatteryOptimization(result: Result) {
        try {
            val ctx = context ?: run { result.success(false); return }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val intent = Intent(android.provider.Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                    data = Uri.parse("package:${ctx.packageName}")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                ctx.startActivity(intent)
                result.success(true)
            } else {
                result.success(true)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error requesting battery optimization disable", e)
            result.success(false)
        }
    }

    private fun isBatteryOptimizationDisabled(result: Result) {
        try {
            val ctx = context ?: run { result.success(false); return }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val powerManager = ctx.getSystemService(Context.POWER_SERVICE) as PowerManager
                val isIgnoring = powerManager.isIgnoringBatteryOptimizations(ctx.packageName)
                result.success(isIgnoring)
            } else {
                result.success(true)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error checking battery optimization status", e)
            result.success(false)
        }
    }
}
