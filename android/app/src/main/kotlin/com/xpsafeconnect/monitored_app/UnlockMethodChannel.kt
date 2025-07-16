package com.xpsafeconnect.monitored_app

import android.app.KeyguardManager
import android.content.Context
import android.os.Build
import android.os.PowerManager
import androidx.annotation.RequiresApi
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class UnlockMethodChannel(private val context: Context) : MethodCallHandler {
    companion object {
        const val CHANNEL = "com.xpsafeconnect.monitored_app/unlock"
    }

    fun configureChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "unlockDevice" -> {
                val success = unlockDevice()
                result.success(success)
            }
            "isUnlockAvailable" -> {
                val available = isUnlockAvailable()
                result.success(available)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun unlockDevice(): Boolean {
        try {
            // Vérifier si l'appareil est verrouillé
            val keyguardManager = context.getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
            if (!keyguardManager.isKeyguardLocked) {
                // L'appareil est déjà déverrouillé
                return true
            }

            // Réveiller l'appareil s'il est en veille
            val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            if (!powerManager.isInteractive) {
                val wakeLock = powerManager.newWakeLock(
                    PowerManager.FULL_WAKE_LOCK 
                        or PowerManager.ACQUIRE_CAUSES_WAKEUP 
                        or PowerManager.ON_AFTER_RELEASE, 
                    "XPSafeConnect:UnlockWakeLock"
                )
                wakeLock.acquire(10000) // 10 secondes
                wakeLock.release()
            }

            // Pour les appareils Android >= API 23, on peut utiliser KeyguardManager.requestDismissKeyguard
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                return requestDismissKeyguard(keyguardManager)
            }

            // Pour les anciennes versions, on ne peut pas déverrouiller directement
            return false
        } catch (e: Exception) {
            e.printStackTrace()
            return false
        }
    }

    @RequiresApi(Build.VERSION_CODES.M)
    private fun requestDismissKeyguard(keyguardManager: KeyguardManager): Boolean {
        try {
            // Vérifier si l'application a les permissions d'administrateur
            if (keyguardManager.isDeviceSecure) {
                // Nécessite une activité pour être appelé
                return false
            } else {
                // Si l'appareil n'a pas de sécurité configurée, on peut essayer de déverrouiller
                return true
            }
        } catch (e: Exception) {
            e.printStackTrace()
            return false
        }
    }

    private fun isUnlockAvailable(): Boolean {
        // Vérifie si la fonctionnalité de déverrouillage est disponible sur cet appareil
        val keyguardManager = context.getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
        
        // Les appareils Android 6.0+ avec KeyguardManager
        return Build.VERSION.SDK_INT >= Build.VERSION_CODES.M
    }
}