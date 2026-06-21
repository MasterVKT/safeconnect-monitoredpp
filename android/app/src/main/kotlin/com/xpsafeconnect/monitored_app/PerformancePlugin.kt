package com.xpsafeconnect.monitored_app

import android.app.ActivityManager
import android.content.Context
import android.net.TrafficStats
import android.os.Build
import android.os.StatFs
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.FileNotFoundException
import java.io.FileReader

class PerformancePlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private data class CpuSnapshot(val total: Long, val idle: Long)

    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var lastTxBytes: Long = 0
    private var lastRxBytes: Long = 0
    private var lastNetworkTime: Long = 0
    private var lastCpuTotal: Long? = null
    private var lastCpuIdle: Long? = null
    private var lastProcessCpuMs: Long = 0
    private var lastProcessSampleTimeMs: Long = 0
    private var hasLoggedCpuAccessWarning: Boolean = false

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.xpsafeconnect.monitored_app/performance")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getCpuUsage" -> {
                val cpuUsage = getCpuUsage()
                result.success(cpuUsage)
            }
            "getMemoryInfo" -> {
                val memoryInfo = getMemoryInfo()
                result.success(memoryInfo)
            }
            "getStorageInfo" -> {
                val storageInfo = getStorageInfo()
                result.success(storageInfo)
            }
            "getNetworkInfo" -> {
                val networkInfo = getNetworkInfo()
                result.success(networkInfo)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    private fun getCpuUsage(): Double {
        val cpuSnapshot = readCpuSnapshot()
        if (cpuSnapshot != null) {
            val previousTotal = lastCpuTotal
            val previousIdle = lastCpuIdle

            lastCpuTotal = cpuSnapshot.total
            lastCpuIdle = cpuSnapshot.idle

            if (previousTotal == null || previousIdle == null) {
                return 0.0
            }

            val totalDiff = cpuSnapshot.total - previousTotal
            val idleDiff = cpuSnapshot.idle - previousIdle
            if (totalDiff <= 0) {
                return 0.0
            }

            val usage = ((totalDiff - idleDiff).toDouble() / totalDiff.toDouble()) * 100.0
            return usage.coerceIn(0.0, 100.0)
        }

        return getProcessCpuUsageFallback()
    }

    private fun readCpuSnapshot(): CpuSnapshot? {
        return try {
            val load = BufferedReader(FileReader("/proc/stat")).use { it.readLine() } ?: return null
            val tokens = load.trim().split(Regex("\\s+"))
            if (tokens.size < 8 || tokens[0] != "cpu") {
                return null
            }

            val user = tokens[1].toLong()
            val nice = tokens[2].toLong()
            val system = tokens[3].toLong()
            val idle = tokens[4].toLong()
            val iowait = tokens.getOrNull(5)?.toLongOrNull() ?: 0L
            val irq = tokens.getOrNull(6)?.toLongOrNull() ?: 0L
            val softIrq = tokens.getOrNull(7)?.toLongOrNull() ?: 0L
            val steal = tokens.getOrNull(8)?.toLongOrNull() ?: 0L

            val total = user + nice + system + idle + iowait + irq + softIrq + steal
            CpuSnapshot(total = total, idle = idle + iowait)
        } catch (e: FileNotFoundException) {
            logCpuAccessWarning(e)
            null
        } catch (e: SecurityException) {
            logCpuAccessWarning(e)
            null
        } catch (e: Exception) {
            Log.e("PerformancePlugin", "Error reading CPU snapshot", e)
            null
        }
    }

    private fun getProcessCpuUsageFallback(): Double {
        return try {
            val nowMs = System.currentTimeMillis()
            val processCpuMs = android.os.Process.getElapsedCpuTime()

            if (lastProcessSampleTimeMs == 0L) {
                lastProcessSampleTimeMs = nowMs
                lastProcessCpuMs = processCpuMs
                return 0.0
            }

            val elapsedMs = nowMs - lastProcessSampleTimeMs
            val processDiffMs = processCpuMs - lastProcessCpuMs

            lastProcessSampleTimeMs = nowMs
            lastProcessCpuMs = processCpuMs

            if (elapsedMs <= 0L || processDiffMs < 0L) {
                return 0.0
            }

            val cpuCores = Runtime.getRuntime().availableProcessors().coerceAtLeast(1)
            val usage = (processDiffMs.toDouble() / (elapsedMs.toDouble() * cpuCores.toDouble())) * 100.0
            usage.coerceIn(0.0, 100.0)
        } catch (e: Exception) {
            Log.e("PerformancePlugin", "Error getting process CPU fallback", e)
            0.0
        }
    }

    private fun logCpuAccessWarning(error: Exception) {
        if (!hasLoggedCpuAccessWarning) {
            Log.w(
                "PerformancePlugin",
                "CPU global metrics unavailable on this device; using process-level fallback (${error::class.java.simpleName})."
            )
            hasLoggedCpuAccessWarning = true
        }
    }

    private fun getMemoryInfo(): Map<String, Any> {
        return try {
            val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            val memoryInfo = ActivityManager.MemoryInfo()
            activityManager.getMemoryInfo(memoryInfo)

            val totalMemoryMB = memoryInfo.totalMem / (1024 * 1024)
            val availableMemoryMB = memoryInfo.availMem / (1024 * 1024)
            val usedMemoryMB = totalMemoryMB - availableMemoryMB
            val usagePercent = (usedMemoryMB.toDouble() / totalMemoryMB.toDouble()) * 100.0

            mapOf(
                "total_mb" to totalMemoryMB.toInt(),
                "used_mb" to usedMemoryMB.toInt(),
                "usage_percent" to usagePercent
            )
        } catch (e: Exception) {
            Log.e("PerformancePlugin", "Error getting memory info", e)
            mapOf(
                "total_mb" to 0,
                "used_mb" to 0,
                "usage_percent" to 0.0
            )
        }
    }

    private fun getStorageInfo(): Map<String, Any> {
        return try {
            val stat = StatFs(context.filesDir.path)
            val blockSizeBytes = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR2) {
                stat.blockSizeLong
            } else {
                stat.blockSize.toLong()
            }
            
            val totalBlocks = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR2) {
                stat.blockCountLong
            } else {
                stat.blockCount.toLong()
            }
            
            val availableBlocks = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR2) {
                stat.availableBlocksLong
            } else {
                stat.availableBlocks.toLong()
            }

            val totalMB = (totalBlocks * blockSizeBytes) / (1024 * 1024)
            val availableMB = (availableBlocks * blockSizeBytes) / (1024 * 1024)
            val usedMB = totalMB - availableMB

            mapOf(
                "total_mb" to totalMB.toInt(),
                "used_mb" to usedMB.toInt()
            )
        } catch (e: Exception) {
            Log.e("PerformancePlugin", "Error getting storage info", e)
            mapOf(
                "total_mb" to 0,
                "used_mb" to 0
            )
        }
    }

    private fun getNetworkInfo(): Map<String, Any> {
        return try {
            val currentTime = System.currentTimeMillis()
            val currentTxBytes = TrafficStats.getTotalTxBytes()
            val currentRxBytes = TrafficStats.getTotalRxBytes()

            val uploadKbps = if (lastNetworkTime > 0) {
                val timeDiffSeconds = (currentTime - lastNetworkTime) / 1000.0
                val bytesDiff = currentTxBytes - lastTxBytes
                if (timeDiffSeconds > 0) {
                    (bytesDiff / timeDiffSeconds) / 1024.0
                } else 0.0
            } else 0.0

            val downloadKbps = if (lastNetworkTime > 0) {
                val timeDiffSeconds = (currentTime - lastNetworkTime) / 1000.0
                val bytesDiff = currentRxBytes - lastRxBytes
                if (timeDiffSeconds > 0) {
                    (bytesDiff / timeDiffSeconds) / 1024.0
                } else 0.0
            } else 0.0

            // Update last values for next calculation
            lastTxBytes = currentTxBytes
            lastRxBytes = currentRxBytes
            lastNetworkTime = currentTime

            mapOf(
                "upload_kbps" to uploadKbps,
                "download_kbps" to downloadKbps
            )
        } catch (e: Exception) {
            Log.e("PerformancePlugin", "Error getting network info", e)
            mapOf(
                "upload_kbps" to 0.0,
                "download_kbps" to 0.0
            )
        }
    }
}
