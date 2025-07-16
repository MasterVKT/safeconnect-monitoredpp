package com.xpsafeconnect.monitored_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Initialize unlock method channel
        UnlockMethodChannel(context).configureChannel(flutterEngine)

        flutterEngine.plugins.add(UnlockDevicePlugin())
        flutterEngine.plugins.add(UnlockDevicePlugin())
        flutterEngine.plugins.add(SmsCollectorPlugin())
        flutterEngine.plugins.add(CallsCollectorPlugin())
        flutterEngine.plugins.add(AppsCollectorPlugin())
        flutterEngine.plugins.add(MediaCapturePlugin())
        flutterEngine.plugins.add(BatteryOptimizationPlugin())

        // Configure background service channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BACKGROUND_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startService" -> {
                    val callbackHandle = call.argument<Long>("callback_handle")
                    if (callbackHandle != null) {
                        BackgroundCollectorService.startService(this, callbackHandle)
                        result.success(true)
                    } else {
                        result.error("INVALID_CALLBACK", "No callback handle provided", null)
                    }
                }
                "stopService" -> {
                    BackgroundCollectorService.stopService(this)
                    result.success(true)
                }
                "isServiceRunning" -> {
                    // Logique pour vérifier si le service tourne
                    // Ceci est une simplification
                    val isRunning = BackgroundCollectorService.isRunning()
                    result.success(isRunning)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Vérifier si l'application a été lancée par le démarrage du système
        val intent = intent
        if (intent.action == Intent.ACTION_MAIN && intent.hasCategory(Intent.CATEGORY_LAUNCHER)) {
            // L'application a été lancée normalement
        } else {
            // L'application a peut-être été lancée par le service
            val sharedPreferences = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
            val autoStartEnabled = sharedPreferences.getBoolean("auto_start_enabled", true)
            val isConfigured = sharedPreferences.getBoolean("is_configured", false)
            
            if (autoStartEnabled && isConfigured) {
                val callbackHandle = sharedPreferences.getLong("callback_handle", 0)
                if (callbackHandle != 0L) {
                    BackgroundCollectorService.startService(this, callbackHandle)
                }
            }
        }
    }
}