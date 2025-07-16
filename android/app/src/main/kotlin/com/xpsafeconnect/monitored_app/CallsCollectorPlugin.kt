package com.xpsafeconnect.monitored_app

import android.Manifest
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.database.Cursor
import android.net.Uri
import android.provider.CallLog
import android.telephony.PhoneStateListener
import android.telephony.TelephonyManager
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.*

class CallsCollectorPlugin: FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var telephonyManager: TelephonyManager? = null
    private var phoneStateListener: PhoneStateListener? = null
    private var callReceiver: BroadcastReceiver? = null
    private var isReceiverRegistered = false
    private var isListenerRegistered = false

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.xpsafeconnect.monitored_app/calls")
        context = flutterPluginBinding.applicationContext
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "checkCallLogPermissions" -> {
                result.success(checkCallLogPermissions())
            }
            "startCallTracking" -> {
                startCallTracking()
                result.success(true)
            }
            "stopCallTracking" -> {
                stopCallTracking()
                result.success(true)
            }
            "getNewCalls" -> {
                val timestamp = call.argument<Long>("since") ?: 0
                val calls = getNewCalls(timestamp)
                result.success(calls)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun checkCallLogPermissions(): Boolean {
        return ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.READ_CALL_LOG
        ) == PackageManager.PERMISSION_GRANTED &&
                ContextCompat.checkSelfPermission(
                        context,
                        Manifest.permission.READ_PHONE_STATE
                ) == PackageManager.PERMISSION_GRANTED
    }

    private fun startCallTracking() {
        if (!checkCallLogPermissions()) {
            return
        }

        // Register phone state listener
        if (telephonyManager == null) {
            telephonyManager = context.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
        }

        if (phoneStateListener == null) {
            phoneStateListener = object : PhoneStateListener() {
                override fun onCallStateChanged(state: Int, phoneNumber: String?) {
                    super.onCallStateChanged(state, phoneNumber)
                    
                    // Send call state change notification to Flutter
                    val callData = mapOf(
                            "state" to state,
                            "number" to (phoneNumber ?: ""),
                            "timestamp" to System.currentTimeMillis()
                    )
                    channel.invokeMethod("onCallStateChanged", callData)
                }
            }
        }

        if (!isListenerRegistered) {
            telephonyManager?.listen(phoneStateListener, PhoneStateListener.LISTEN_CALL_STATE)
            isListenerRegistered = true
        }

        // Register broadcast receiver for outgoing calls
        if (callReceiver == null) {
            callReceiver = object : BroadcastReceiver() {
                override fun onReceive(context: Context, intent: Intent) {
                    val number = intent.getStringExtra(Intent.EXTRA_PHONE_NUMBER)
                    val callData = mapOf(
                            "state" to TelephonyManager.CALL_STATE_OFFHOOK,
                            "number" to (number ?: ""),
                            "timestamp" to System.currentTimeMillis(),
                            "outgoing" to true
                    )
                    channel.invokeMethod("onCallStateChanged", callData)
                }
            }
        }

        if (!isReceiverRegistered) {
            val intentFilter = IntentFilter(Intent.ACTION_NEW_OUTGOING_CALL)
            context.registerReceiver(callReceiver, intentFilter)
            isReceiverRegistered = true
        }
    }

    private fun stopCallTracking() {
        if (telephonyManager != null && phoneStateListener != null && isListenerRegistered) {
            telephonyManager?.listen(phoneStateListener, PhoneStateListener.LISTEN_NONE)
            isListenerRegistered = false
        }

        if (callReceiver != null && isReceiverRegistered) {
            context.unregisterReceiver(callReceiver)
            isReceiverRegistered = false
        }
    }

    private fun getNewCalls(since: Long): List<Map<String, Any>> {
        val result = ArrayList<Map<String, Any>>()
        if (!checkCallLogPermissions()) {
            return result
        }

        val uri = CallLog.Calls.CONTENT_URI
        val projection = arrayOf(
                CallLog.Calls._ID,
                CallLog.Calls.NUMBER,
                CallLog.Calls.TYPE,
                CallLog.Calls.DATE,
                CallLog.Calls.DURATION,
                CallLog.Calls.CACHED_NAME
        )
        val selection = "${CallLog.Calls.DATE} > ?"
        val selectionArgs = arrayOf(since.toString())
        val sortOrder = "${CallLog.Calls.DATE} DESC"

        var cursor: Cursor? = null
        try {
            cursor = context.contentResolver.query(
                    uri,
                    projection,
                    selection,
                    selectionArgs,
                    sortOrder
            )

            cursor?.let {
                while (it.moveToNext()) {
                    val callData = mapOf(
                            "number" to (it.getString(it.getColumnIndexOrThrow(CallLog.Calls.NUMBER)) ?: ""),
                            "type" to it.getInt(it.getColumnIndexOrThrow(CallLog.Calls.TYPE)),
                            "date" to it.getLong(it.getColumnIndexOrThrow(CallLog.Calls.DATE)),
                            "duration" to it.getLong(it.getColumnIndexOrThrow(CallLog.Calls.DURATION)),
                            "name" to (it.getString(it.getColumnIndexOrThrow(CallLog.Calls.CACHED_NAME)) ?: ""),
                            "sim_slot" to -1, // Not available in basic API
                            "is_conference" to false // Not available in basic API
                    )
                    result.add(callData)
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        } finally {
            cursor?.close()
        }

        return result
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        stopCallTracking()
        channel.setMethodCallHandler(null)
    }
}