package com.xpsafeconnect.monitored_app

import android.Manifest
import android.content.ContentResolver
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.database.Cursor
import android.os.Build
import android.os.Bundle
import android.provider.CallLog
import android.util.Log
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
    companion object {
        private const val TAG = "CallsCollectorPlugin"
    }

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
                val limit = call.argument<Int>("limit") ?: 500
                try {
                    result.success(getNewCalls(timestamp, limit))
                } catch (e: Exception) {
                    Log.e(TAG, "getNewCalls query failed", e)
                    result.error(
                            "CALL_LOG_QUERY_FAILED",
                            "Unable to query call log",
                            null
                    )
                }
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

    private fun getNewCalls(since: Long, limit: Int = 500): List<Map<String, Any>> {
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
        val safeLimit = limit.coerceIn(1, 1000)

        var cursor: Cursor? = null
        try {
            cursor = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val args = Bundle().apply {
                    putString(
                            ContentResolver.QUERY_ARG_SQL_SELECTION,
                            "${CallLog.Calls.DATE} > ?"
                    )
                    putStringArray(
                            ContentResolver.QUERY_ARG_SQL_SELECTION_ARGS,
                            arrayOf(since.toString())
                    )
                    putStringArray(
                            ContentResolver.QUERY_ARG_SORT_COLUMNS,
                            arrayOf(CallLog.Calls.DATE)
                    )
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
                    "${CallLog.Calls.DATE} > ?",
                    arrayOf(since.toString()),
                    "${CallLog.Calls.DATE} ASC"
                )
            }

            cursor?.let {
                var count = 0
                while (it.moveToNext() && count < safeLimit) {
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
                    count++
                }
            }
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
