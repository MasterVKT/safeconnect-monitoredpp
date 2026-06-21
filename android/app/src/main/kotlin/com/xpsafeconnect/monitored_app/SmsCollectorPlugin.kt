package com.xpsafeconnect.monitored_app

import android.Manifest
import android.content.ContentResolver
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Telephony
import android.util.Log
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.*

class SmsCollectorPlugin: FlutterPlugin, MethodCallHandler {
    companion object {
        private const val TAG = "SmsCollectorPlugin"
    }

    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var smsReceiver: BroadcastReceiver? = null
    private var isReceiverRegistered = false

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.xpsafeconnect.monitored_app/sms")
        context = flutterPluginBinding.applicationContext
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "checkSmsPermissions" -> {
                result.success(checkSmsPermissions())
            }
            "startSmsTracking" -> {
                startSmsTracking()
                result.success(true)
            }
            "stopSmsTracking" -> {
                stopSmsTracking()
                result.success(true)
            }
            "getNewSms" -> {
                val timestamp = call.argument<Long>("since") ?: 0
                val limit = call.argument<Int>("limit") ?: 500
                try {
                    result.success(getNewSms(timestamp, limit))
                } catch (e: Exception) {
                    Log.e(TAG, "getNewSms query failed", e)
                    result.error("SMS_QUERY_FAILED", "Unable to query SMS", null)
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun checkSmsPermissions(): Boolean {
        return ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.READ_SMS
        ) == PackageManager.PERMISSION_GRANTED &&
                ContextCompat.checkSelfPermission(
                        context,
                        Manifest.permission.RECEIVE_SMS
                ) == PackageManager.PERMISSION_GRANTED
    }

    private fun startSmsTracking() {
        if (!checkSmsPermissions()) {
            Log.d(TAG, "SMS tracking not started: permissions missing")
            return
        }

        if (smsReceiver == null) {
            smsReceiver = object : BroadcastReceiver() {
                override fun onReceive(context: Context, intent: Intent) {
                    if (Telephony.Sms.Intents.SMS_RECEIVED_ACTION == intent.action) {
                        for (smsMessage in Telephony.Sms.Intents.getMessagesFromIntent(intent)) {
                            val smsData = mapOf(
                                    "sender" to smsMessage.originatingAddress,
                                    "recipient" to "",
                                    "body" to smsMessage.messageBody,
                                    "date" to System.currentTimeMillis(),
                                    "type" to 1, // Incoming
                                    "read" to 0,
                                    "thread_id" to 0
                            )

                            channel.invokeMethod("onSmsReceived", smsData)
                        }
                    }
                }
            }
        }

        if (!isReceiverRegistered) {
            val intentFilter = IntentFilter(Telephony.Sms.Intents.SMS_RECEIVED_ACTION)
            context.registerReceiver(smsReceiver, intentFilter)
            isReceiverRegistered = true
        }
    }

    private fun stopSmsTracking() {
        if (smsReceiver != null && isReceiverRegistered) {
            context.unregisterReceiver(smsReceiver)
            isReceiverRegistered = false
        }
    }

    private fun getNewSms(since: Long, limit: Int = 500): List<Map<String, Any>> {
        val result = ArrayList<Map<String, Any>>()
        if (!checkSmsPermissions()) {
            Log.d(TAG, "getNewSms skipped: permissions missing")
            return result
        }

        val uri = Uri.parse("content://sms")
        val projection = arrayOf(
                Telephony.Sms._ID,
                Telephony.Sms.ADDRESS,
                Telephony.Sms.BODY,
                Telephony.Sms.DATE,
                Telephony.Sms.TYPE,
                Telephony.Sms.READ,
                Telephony.Sms.THREAD_ID
        )
        val safeLimit = limit.coerceIn(1, 1000)

        var cursor: Cursor? = null
        try {
            cursor = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val args = Bundle().apply {
                    putString(
                            ContentResolver.QUERY_ARG_SQL_SELECTION,
                            "${Telephony.Sms.DATE} > ?"
                    )
                    putStringArray(
                            ContentResolver.QUERY_ARG_SQL_SELECTION_ARGS,
                            arrayOf(since.toString())
                    )
                    putStringArray(
                            ContentResolver.QUERY_ARG_SORT_COLUMNS,
                            arrayOf(Telephony.Sms.DATE)
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
                    "${Telephony.Sms.DATE} > ?",
                    arrayOf(since.toString()),
                    "${Telephony.Sms.DATE} ASC"
                )
            }
            Log.d(TAG, "getNewSms query returned ${cursor?.count ?: 0} rows since $since")

            cursor?.let {
                var count = 0
                while (it.moveToNext() && count < safeLimit) {
                    val type = it.getInt(it.getColumnIndexOrThrow(Telephony.Sms.TYPE))
                    val address = it.getString(it.getColumnIndexOrThrow(Telephony.Sms.ADDRESS))
                    
                    // Determine sender and recipient based on type
                    val sender: String
                    val recipient: String
                    if (type == Telephony.Sms.MESSAGE_TYPE_INBOX) {
                        sender = address ?: ""
                        recipient = ""
                    } else {
                        sender = ""
                        recipient = address ?: ""
                    }

                    val smsData = mapOf(
                            "sender" to sender,
                            "recipient" to recipient,
                            "body" to it.getString(it.getColumnIndexOrThrow(Telephony.Sms.BODY)),
                            "date" to it.getLong(it.getColumnIndexOrThrow(Telephony.Sms.DATE)),
                            "type" to type,
                            "read" to it.getInt(it.getColumnIndexOrThrow(Telephony.Sms.READ)),
                            "thread_id" to it.getLong(it.getColumnIndexOrThrow(Telephony.Sms.THREAD_ID))
                    )
                    result.add(smsData)
                    count++
                }
            }
        } finally {
            cursor?.close()
        }

        return result
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        stopSmsTracking()
        channel.setMethodCallHandler(null)
    }
}
