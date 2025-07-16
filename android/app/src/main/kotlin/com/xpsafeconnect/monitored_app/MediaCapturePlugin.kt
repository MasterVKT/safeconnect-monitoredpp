package com.xpsafeconnect.monitored_app

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.hardware.camera2.CameraAccessException
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.view.Surface
import android.view.WindowManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File
import java.io.FileOutputStream
import java.text.SimpleDateFormat
import java.util.*
import java.util.concurrent.Executors

class MediaCapturePlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var activity: Activity? = null
    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.xpsafeconnect.monitored_app/media")
        context = flutterPluginBinding.applicationContext
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "checkMediaPermissions" -> {
                result.success(checkMediaPermissions())
            }
            "requestMediaPermissions" -> {
                if (activity == null) {
                    result.error("NO_ACTIVITY", "No activity available to request permissions", null)
                    return
                }
                requestMediaPermissions(result)
            }
            "captureScreenshot" -> {
                executor.execute {
                    val filePath = captureScreenshot()
                    mainHandler.post {
                        result.success(filePath)
                    }
                }
            }
            "capturePhoto" -> {
                val frontCamera = call.argument<Boolean>("front_camera") ?: false
                executor.execute {
                    val filePath = capturePhoto(frontCamera)
                    mainHandler.post {
                        result.success(filePath)
                    }
                }
            }
            "recordAudio" -> {
                val durationSeconds = call.argument<Int>("duration_seconds") ?: 30
                executor.execute {
                    val filePath = recordAudio(durationSeconds)
                    mainHandler.post {
                        result.success(filePath)
                    }
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun checkMediaPermissions(): Boolean {
        val cameraPermission = ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.CAMERA
        ) == PackageManager.PERMISSION_GRANTED

        val storagePermission = ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.WRITE_EXTERNAL_STORAGE
        ) == PackageManager.PERMISSION_GRANTED

        val audioPermission = ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.RECORD_AUDIO
        ) == PackageManager.PERMISSION_GRANTED

        return cameraPermission && storagePermission && audioPermission
    }

    private fun requestMediaPermissions(result: Result) {
        // This requires ActivityAware implementation to get the activity
        if (activity == null) {
            result.error("NO_ACTIVITY", "No activity available to request permissions", null)
            return
        }

        val permissions = arrayOf(
                Manifest.permission.CAMERA,
                Manifest.permission.WRITE_EXTERNAL_STORAGE,
                Manifest.permission.RECORD_AUDIO
        )

        ActivityCompat.requestPermissions(activity!!, permissions, 0)
        
        // Note: In a real implementation, you would register a permission result callback
        // For this example, we'll just check if permissions are granted now
        result.success(checkMediaPermissions())
    }

    private fun captureScreenshot(): String? {
        if (!checkMediaPermissions()) {
            return null
        }

        try {
            // Create a file to save the screenshot
            val fileName = "screenshot_${SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(Date())}.jpg"
            val storageDir = context.getExternalFilesDir(Environment.DIRECTORY_PICTURES)
            val imageFile = File(storageDir, fileName)

            // Get the screenshot
            activity?.let {
                val view = it.window.decorView.rootView
                view.isDrawingCacheEnabled = true
                val bitmap = Bitmap.createBitmap(view.drawingCache)
                view.isDrawingCacheEnabled = false

                FileOutputStream(imageFile).use { fos ->
                    bitmap.compress(Bitmap.CompressFormat.JPEG, 90, fos)
                    fos.flush()
                }

                return imageFile.absolutePath
            }

            return null
        } catch (e: Exception) {
            e.printStackTrace()
            return null
        }
    }

    private fun capturePhoto(frontCamera: Boolean): String? {
        if (!checkMediaPermissions() || activity == null) {
            return null
        }

        try {
            val cameraManager = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
            val cameraId = getCameraId(cameraManager, frontCamera)
            
            if (cameraId == null) {
                return null
            }
            
            // In a real implementation, this would use Camera2 API or CameraX
            // For this example, we'll create a placeholder image file
            
            val fileName = "photo_${SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(Date())}.jpg"
            val storageDir = context.getExternalFilesDir(Environment.DIRECTORY_PICTURES)
            val imageFile = File(storageDir, fileName)
            
            // This is a placeholder. In a real app, you would capture from camera
            val bitmap = Bitmap.createBitmap(640, 480, Bitmap.Config.ARGB_8888)
            
            FileOutputStream(imageFile).use { fos ->
                bitmap.compress(Bitmap.CompressFormat.JPEG, 90, fos)
                fos.flush()
            }
            
            return imageFile.absolutePath
        } catch (e: Exception) {
            e.printStackTrace()
            return null
        }
    }

    private fun recordAudio(durationSeconds: Int): String? {
        if (!checkMediaPermissions()) {
            return null
        }

        try {
            val fileName = "audio_${SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(Date())}.m4a"
            val storageDir = context.getExternalFilesDir(Environment.DIRECTORY_MUSIC)
            val audioFile = File(storageDir, fileName)

            // In a real implementation, this would use MediaRecorder
            // For this example, we'll create a placeholder audio file
            
            // Create an empty file
            audioFile.createNewFile()
            
            // Wait for the duration to simulate recording
            Thread.sleep(1000)
            
            return audioFile.absolutePath
        } catch (e: Exception) {
            e.printStackTrace()
            return null
        }
    }

    private fun getCameraId(cameraManager: CameraManager, frontFacing: Boolean): String? {
        try {
            for (cameraId in cameraManager.cameraIdList) {
                val characteristics = cameraManager.getCameraCharacteristics(cameraId)
                val lensFacing = characteristics.get(CameraCharacteristics.LENS_FACING)
                
                if (frontFacing && lensFacing == CameraCharacteristics.LENS_FACING_FRONT) {
                    return cameraId
                } else if (!frontFacing && lensFacing == CameraCharacteristics.LENS_FACING_BACK) {
                    return cameraId
                }
            }
        } catch (e: CameraAccessException) {
            e.printStackTrace()
        }
        
        return null
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        executor.shutdown()
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
}