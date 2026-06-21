package com.xpsafeconnect.monitored_app

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Build
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class BatteryMonitorPlugin: FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var batteryManager: BatteryManager? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.xpsafeconnect.monitored_app/battery_monitor")
        channel.setMethodCallHandler(this)
        
        // Initialize battery manager
        batteryManager = context.getSystemService(Context.BATTERY_SERVICE) as? BatteryManager
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "getBatteryInfo" -> getBatteryInfo(result)
            "getScreenOnTime" -> getScreenOnTime(result)
            "getTopDrainingApps" -> getTopDrainingApps(result)
            "getBatteryCycleCount" -> getBatteryCycleCount(result)
            "getBatteryCapacity" -> getBatteryCapacity(result)
            "getBatteryTemperature" -> getBatteryTemperature(result)
            "getBatteryVoltage" -> getBatteryVoltage(result)
            "getBatteryHealth" -> getBatteryHealth(result)
            else -> result.notImplemented()
        }
    }

    private fun getBatteryInfo(result: Result) {
        try {
            val batteryStatus = context.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
            
            if (batteryStatus != null) {
                val level = batteryStatus.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
                val scale = batteryStatus.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
                val batteryPct = (level * 100 / scale.toFloat()).toInt()
                
                val status = batteryStatus.getIntExtra(BatteryManager.EXTRA_STATUS, -1)
                val health = batteryStatus.getIntExtra(BatteryManager.EXTRA_HEALTH, -1)
                val plugged = batteryStatus.getIntExtra(BatteryManager.EXTRA_PLUGGED, -1)
                val present = batteryStatus.getBooleanExtra(BatteryManager.EXTRA_PRESENT, false)
                val technology = batteryStatus.getStringExtra(BatteryManager.EXTRA_TECHNOLOGY) ?: "Unknown"
                val temperature = batteryStatus.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, -1)
                val voltage = batteryStatus.getIntExtra(BatteryManager.EXTRA_VOLTAGE, -1)

                val batteryInfo = mapOf(
                    "level" to batteryPct,
                    "status" to getStatusString(status),
                    "health" to getHealthString(health),
                    "plugged" to getPluggedString(plugged),
                    "present" to present,
                    "technology" to technology,
                    "temperature" to temperature, // in tenths of degree Celsius
                    "voltage" to voltage, // in millivolts
                    "capacity" to getBatteryCapacityInternal(),
                    "charge_counter" to getChargeCounter(),
                    "current_average" to getCurrentAverage(),
                    "current_now" to getCurrentNow(),
                    "energy_counter" to getEnergyCounter()
                )
                
                result.success(batteryInfo)
            } else {
                result.error("BATTERY_INFO_ERROR", "Could not retrieve battery information", null)
            }
        } catch (e: Exception) {
            result.error("BATTERY_INFO_ERROR", "Error getting battery info: ${e.message}", null)
        }
    }

    private fun getScreenOnTime(result: Result) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                // This would require usage stats permission and proper implementation
                // For now, return 0 as placeholder
                result.success(0)
            } else {
                result.success(0)
            }
        } catch (e: Exception) {
            result.error("SCREEN_TIME_ERROR", "Error getting screen on time: ${e.message}", null)
        }
    }

    private fun getTopDrainingApps(result: Result) {
        try {
            // This would require detailed battery statistics implementation
            // For now, return empty list as placeholder
            val topApps = listOf<String>()
            result.success(topApps)
        } catch (e: Exception) {
            result.error("DRAINING_APPS_ERROR", "Error getting top draining apps: ${e.message}", null)
        }
    }

    private fun getBatteryCycleCount(result: Result) {
        try {
            // Battery cycle count is not directly available on Android
            // Would need to implement estimation based on charge/discharge patterns
            result.success(0)
        } catch (e: Exception) {
            result.error("CYCLE_COUNT_ERROR", "Error getting battery cycle count: ${e.message}", null)
        }
    }

    private fun getBatteryCapacity(result: Result) {
        try {
            val capacity = getBatteryCapacityInternal()
            result.success(capacity)
        } catch (e: Exception) {
            result.error("CAPACITY_ERROR", "Error getting battery capacity: ${e.message}", null)
        }
    }

    private fun getBatteryTemperature(result: Result) {
        try {
            val batteryStatus = context.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
            val temperature = batteryStatus?.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, -1) ?: -1
            result.success(temperature) // in tenths of degree Celsius
        } catch (e: Exception) {
            result.error("TEMPERATURE_ERROR", "Error getting battery temperature: ${e.message}", null)
        }
    }

    private fun getBatteryVoltage(result: Result) {
        try {
            val batteryStatus = context.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
            val voltage = batteryStatus?.getIntExtra(BatteryManager.EXTRA_VOLTAGE, -1) ?: -1
            result.success(voltage) // in millivolts
        } catch (e: Exception) {
            result.error("VOLTAGE_ERROR", "Error getting battery voltage: ${e.message}", null)
        }
    }

    private fun getBatteryHealth(result: Result) {
        try {
            val batteryStatus = context.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
            val health = batteryStatus?.getIntExtra(BatteryManager.EXTRA_HEALTH, -1) ?: -1
            result.success(getHealthString(health))
        } catch (e: Exception) {
            result.error("HEALTH_ERROR", "Error getting battery health: ${e.message}", null)
        }
    }

    private fun getBatteryCapacityInternal(): Int {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP && batteryManager != null) {
                val capacity = batteryManager!!.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
                if (capacity != Int.MIN_VALUE) capacity else 0
            } else {
                0
            }
        } catch (e: Exception) {
            0
        }
    }

    private fun getChargeCounter(): Long {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP && batteryManager != null) {
                val counter = batteryManager!!.getLongProperty(BatteryManager.BATTERY_PROPERTY_CHARGE_COUNTER)
                if (counter != Long.MIN_VALUE) counter else 0L
            } else {
                0L
            }
        } catch (e: Exception) {
            0L
        }
    }

    private fun getCurrentAverage(): Int {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP && batteryManager != null) {
                val current = batteryManager!!.getIntProperty(BatteryManager.BATTERY_PROPERTY_CURRENT_AVERAGE)
                if (current != Int.MIN_VALUE) current else 0
            } else {
                0
            }
        } catch (e: Exception) {
            0
        }
    }

    private fun getCurrentNow(): Int {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP && batteryManager != null) {
                val current = batteryManager!!.getIntProperty(BatteryManager.BATTERY_PROPERTY_CURRENT_NOW)
                if (current != Int.MIN_VALUE) current else 0
            } else {
                0
            }
        } catch (e: Exception) {
            0
        }
    }

    private fun getEnergyCounter(): Long {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP && batteryManager != null) {
                val energy = batteryManager!!.getLongProperty(BatteryManager.BATTERY_PROPERTY_ENERGY_COUNTER)
                if (energy != Long.MIN_VALUE) energy else 0L
            } else {
                0L
            }
        } catch (e: Exception) {
            0L
        }
    }

    private fun getStatusString(status: Int): String {
        return when (status) {
            BatteryManager.BATTERY_STATUS_CHARGING -> "charging"
            BatteryManager.BATTERY_STATUS_DISCHARGING -> "discharging"
            BatteryManager.BATTERY_STATUS_FULL -> "full"
            BatteryManager.BATTERY_STATUS_NOT_CHARGING -> "not_charging"
            else -> "unknown"
        }
    }

    private fun getHealthString(health: Int): String {
        return when (health) {
            BatteryManager.BATTERY_HEALTH_GOOD -> "good"
            BatteryManager.BATTERY_HEALTH_OVERHEAT -> "overheat"
            BatteryManager.BATTERY_HEALTH_DEAD -> "dead"
            BatteryManager.BATTERY_HEALTH_OVER_VOLTAGE -> "over_voltage"
            BatteryManager.BATTERY_HEALTH_UNSPECIFIED_FAILURE -> "unspecified_failure"
            BatteryManager.BATTERY_HEALTH_COLD -> "cold"
            else -> "unknown"
        }
    }

    private fun getPluggedString(plugged: Int): String {
        return when (plugged) {
            BatteryManager.BATTERY_PLUGGED_AC -> "ac"
            BatteryManager.BATTERY_PLUGGED_USB -> "usb"
            BatteryManager.BATTERY_PLUGGED_WIRELESS -> "wireless"
            else -> "unplugged"
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
