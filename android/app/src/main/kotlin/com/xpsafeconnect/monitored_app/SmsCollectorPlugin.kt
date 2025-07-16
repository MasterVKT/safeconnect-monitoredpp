package com.xpsafeconnect.monitored_app

import android.Manifest
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.provider.Telephony
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.*

class SmsCollectorPlugin: FlutterPlugin, MethodCallHandler {
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
                val smsMessages = getNewSms(timestamp)
                result.success(smsMessages)
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

    private fun getNewSms(since: Long): List<Map<String, Any>> {
        val result = ArrayList<Map<String, Any>>()
        if (!checkSmsPermissions()) {
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
        val selection = "${Telephony.Sms.DATE} > ?"
        val selectionArgs = arrayOf(since.toString())
        val sortOrder = "${Telephony.Sms.DATE} DESC"

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
        stopSmsTracking()
        channel.setMethodCallHandler(null)
    }
}