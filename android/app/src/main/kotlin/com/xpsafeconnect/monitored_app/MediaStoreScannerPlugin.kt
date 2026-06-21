package com.xpsafeconnect.monitored_app

import android.Manifest
import android.content.ContentResolver
import android.content.Context
import android.content.pm.PackageManager
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.MediaStore
import android.util.Log
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

class MediaStoreScannerPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    companion object {
        private const val TAG = "MediaStoreScannerPlugin"
        private const val CHANNEL = "com.xpsafeconnect.monitored_app/mediastore_scanner"
    }

    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "checkReadPermissions" -> result.success(hasAnyMediaReadPermission())
            "getReadPermissionStatus" -> result.success(
                    mapOf(
                            "images" to imageReadPermissionStatus(),
                            "videos" to videoReadPermissionStatus(),
                            "audio" to audioReadPermissionStatus()
                    )
            )
            "scanImages" -> {
                if (!hasImageReadPermission()) {
                    result.success(emptyList<Map<String, Any>>())
                    return
                }
                runScan(result) {
                    scanImages(call.argument("since") ?: 0L, call.argument("limit") ?: 500)
                }
            }
            "scanVideos" -> {
                if (!hasVideoReadPermission()) {
                    result.success(emptyList<Map<String, Any>>())
                    return
                }
                runScan(result) {
                    scanVideos(call.argument("since") ?: 0L, call.argument("limit") ?: 500)
                }
            }
            "scanAudio" -> {
                if (!hasAudioReadPermission()) {
                    result.success(emptyList<Map<String, Any>>())
                    return
                }
                runScan(result) {
                    scanAudio(call.argument("since") ?: 0L, call.argument("limit") ?: 500)
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun runScan(
            result: MethodChannel.Result,
            scan: () -> List<Map<String, Any>>
    ) {
        try {
            result.success(scan())
        } catch (e: Exception) {
            Log.e(TAG, "MediaStore scan failed", e)
            result.error("MEDIASTORE_SCAN_FAILED", "Unable to query MediaStore", null)
        }
    }

    private fun hasAnyMediaReadPermission(): Boolean {
        return hasImageReadPermission() || hasVideoReadPermission() || hasAudioReadPermission()
    }

    private fun hasImageReadPermission(): Boolean {
        if (hasVisualUserSelectedPermission()) {
            return true
        }

        return hasPermission(
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    Manifest.permission.READ_MEDIA_IMAGES
                } else {
                    Manifest.permission.READ_EXTERNAL_STORAGE
                }
        )
    }

    private fun imageReadPermissionStatus(): String {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            return if (hasImageReadPermission()) "granted" else "denied"
        }
        if (hasPermission(Manifest.permission.READ_MEDIA_IMAGES)) {
            return "granted"
        }
        return if (hasVisualUserSelectedPermission()) "limited" else "denied"
    }

    private fun hasVideoReadPermission(): Boolean {
        if (hasVisualUserSelectedPermission()) {
            return true
        }

        return hasPermission(
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    Manifest.permission.READ_MEDIA_VIDEO
                } else {
                    Manifest.permission.READ_EXTERNAL_STORAGE
                }
        )
    }

    private fun videoReadPermissionStatus(): String {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            return if (hasVideoReadPermission()) "granted" else "denied"
        }
        if (hasPermission(Manifest.permission.READ_MEDIA_VIDEO)) {
            return "granted"
        }
        return if (hasVisualUserSelectedPermission()) "limited" else "denied"
    }

    private fun hasAudioReadPermission(): Boolean {
        return hasPermission(
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    Manifest.permission.READ_MEDIA_AUDIO
                } else {
                    Manifest.permission.READ_EXTERNAL_STORAGE
                }
        )
    }

    private fun audioReadPermissionStatus(): String {
        return if (hasAudioReadPermission()) "granted" else "denied"
    }

    private fun hasVisualUserSelectedPermission(): Boolean {
        return Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE &&
                hasPermission(Manifest.permission.READ_MEDIA_VISUAL_USER_SELECTED)
    }

    private fun hasPermission(permission: String): Boolean {
        return ContextCompat.checkSelfPermission(context, permission) == PackageManager.PERMISSION_GRANTED
    }

    private fun scanImages(since: Long, limit: Int): List<Map<String, Any>> {
        return queryMediaStore(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                arrayOf(
                        MediaStore.Images.Media._ID,
                        MediaStore.Images.Media.DISPLAY_NAME,
                        MediaStore.Images.Media.SIZE,
                        MediaStore.Images.Media.MIME_TYPE,
                        MediaStore.Images.Media.DATE_ADDED,
                        MediaStore.Images.Media.DATA,
                        MediaStore.Images.Media.WIDTH,
                        MediaStore.Images.Media.HEIGHT
                ),
                MediaStore.Images.Media.DATE_ADDED,
                since,
                limit,
                "PHOTO"
        )
    }

    private fun scanVideos(since: Long, limit: Int): List<Map<String, Any>> {
        return queryMediaStore(
                MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
                arrayOf(
                        MediaStore.Video.Media._ID,
                        MediaStore.Video.Media.DISPLAY_NAME,
                        MediaStore.Video.Media.SIZE,
                        MediaStore.Video.Media.MIME_TYPE,
                        MediaStore.Video.Media.DATE_ADDED,
                        MediaStore.Video.Media.DATA,
                        MediaStore.Video.Media.WIDTH,
                        MediaStore.Video.Media.HEIGHT,
                        MediaStore.Video.Media.DURATION
                ),
                MediaStore.Video.Media.DATE_ADDED,
                since,
                limit,
                "VIDEO"
        )
    }

    private fun scanAudio(since: Long, limit: Int): List<Map<String, Any>> {
        return queryMediaStore(
                MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                arrayOf(
                        MediaStore.Audio.Media._ID,
                        MediaStore.Audio.Media.DISPLAY_NAME,
                        MediaStore.Audio.Media.SIZE,
                        MediaStore.Audio.Media.MIME_TYPE,
                        MediaStore.Audio.Media.DATE_ADDED,
                        MediaStore.Audio.Media.DATA,
                        MediaStore.Audio.Media.DURATION
                ),
                MediaStore.Audio.Media.DATE_ADDED,
                since,
                limit,
                "AUDIO"
        )
    }

    private fun queryMediaStore(
            uri: Uri,
            projection: Array<String>,
            dateColumn: String,
            since: Long,
            limit: Int,
            mediaType: String
    ): List<Map<String, Any>> {
        val result = mutableListOf<Map<String, Any>>()
        val safeLimit = limit.coerceIn(1, 1000)
        val sinceSeconds = since / 1000
        var cursor: Cursor? = null

        try {
            cursor = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val args = Bundle().apply {
                    putString(ContentResolver.QUERY_ARG_SQL_SELECTION, "$dateColumn > ?")
                    putStringArray(ContentResolver.QUERY_ARG_SQL_SELECTION_ARGS, arrayOf(sinceSeconds.toString()))
                    putStringArray(ContentResolver.QUERY_ARG_SORT_COLUMNS, arrayOf(dateColumn))
                    putInt(
                            ContentResolver.QUERY_ARG_SORT_DIRECTION,
                            ContentResolver.QUERY_SORT_DIRECTION_ASCENDING
                    )
                    putInt(ContentResolver.QUERY_ARG_LIMIT, safeLimit)
                }
                context.contentResolver.query(uri, projection, args, null)
            } else {
                context.contentResolver.query(
                        uri,
                        projection,
                        "$dateColumn > ?",
                        arrayOf(sinceSeconds.toString()),
                        "$dateColumn ASC"
                )
            }

            cursor?.let { c ->
                var count = 0
                while (c.moveToNext() && count < safeLimit) {
                    val nativeId = c.getLong(c.getColumnIndexOrThrow(projection[0]))
                    val item = mutableMapOf<String, Any>(
                            "media_id" to "${mediaType.lowercase(Locale.US)}_$nativeId",
                            "media_type" to mediaType,
                            "id_native" to nativeId,
                            "file_name" to (c.getString(c.getColumnIndexOrThrow(projection[1])) ?: ""),
                            "file_size" to c.getLong(c.getColumnIndexOrThrow(projection[2])),
                            "mime_type" to (c.getString(c.getColumnIndexOrThrow(projection[3])) ?: ""),
                            "created_at_epoch" to c.getLong(c.getColumnIndexOrThrow(dateColumn)) * 1000,
                            "file_path" to (c.getString(c.getColumnIndexOrThrow(projection[5])) ?: "")
                    )

                    when (mediaType) {
                        "PHOTO" -> {
                            item["width"] = c.getInt(c.getColumnIndexOrThrow(MediaStore.Images.Media.WIDTH))
                            item["height"] = c.getInt(c.getColumnIndexOrThrow(MediaStore.Images.Media.HEIGHT))
                        }
                        "VIDEO" -> {
                            item["width"] = c.getInt(c.getColumnIndexOrThrow(MediaStore.Video.Media.WIDTH))
                            item["height"] = c.getInt(c.getColumnIndexOrThrow(MediaStore.Video.Media.HEIGHT))
                            item["duration"] = c.getLong(c.getColumnIndexOrThrow(MediaStore.Video.Media.DURATION))
                        }
                        "AUDIO" -> {
                            item["duration"] = c.getLong(c.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION))
                        }
                    }

                    result.add(item)
                    count++
                }
            }
        } finally {
            cursor?.close()
        }

        return result
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
