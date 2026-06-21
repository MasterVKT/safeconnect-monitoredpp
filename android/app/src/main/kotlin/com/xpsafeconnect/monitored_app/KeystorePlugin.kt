package com.xpsafeconnect.monitored_app

import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class KeystorePlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var keystoreManager: KeystoreManager

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.xpsafeconnect.monitored_app/keystore")
        channel.setMethodCallHandler(this)
        keystoreManager = KeystoreManager()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getMasterKey" -> {
                try {
                    val masterKey = keystoreManager.getMasterKey()
                    if (masterKey != null) {
                        result.success(masterKey)
                    } else {
                        result.error("KEYSTORE_ERROR", "Failed to generate master key", null)
                    }
                } catch (e: Exception) {
                    Log.e("KeystorePlugin", "Error getting master key", e)
                    result.error("KEYSTORE_ERROR", e.message, null)
                }
            }
            "encryptData" -> {
                try {
                    val plaintext = call.argument<String>("plaintext")
                    if (plaintext != null) {
                        val encrypted = keystoreManager.encryptData(plaintext)
                        if (encrypted != null) {
                            result.success(encrypted)
                        } else {
                            result.error("ENCRYPTION_ERROR", "Failed to encrypt data", null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "Plaintext is required", null)
                    }
                } catch (e: Exception) {
                    Log.e("KeystorePlugin", "Error encrypting data", e)
                    result.error("ENCRYPTION_ERROR", e.message, null)
                }
            }
            "decryptData" -> {
                try {
                    val encryptedData = call.argument<String>("encryptedData")
                    if (encryptedData != null) {
                        val decrypted = keystoreManager.decryptData(encryptedData)
                        if (decrypted != null) {
                            result.success(decrypted)
                        } else {
                            result.error("DECRYPTION_ERROR", "Failed to decrypt data", null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "Encrypted data is required", null)
                    }
                } catch (e: Exception) {
                    Log.e("KeystorePlugin", "Error decrypting data", e)
                    result.error("DECRYPTION_ERROR", e.message, null)
                }
            }
            "validateKeystore" -> {
                try {
                    val isValid = keystoreManager.validateKeystore()
                    result.success(isValid)
                } catch (e: Exception) {
                    Log.e("KeystorePlugin", "Error validating keystore", e)
                    result.error("VALIDATION_ERROR", e.message, null)
                }
            }
            "deleteMasterKey" -> {
                try {
                    val deleted = keystoreManager.deleteMasterKey()
                    result.success(deleted)
                } catch (e: Exception) {
                    Log.e("KeystorePlugin", "Error deleting master key", e)
                    result.error("DELETE_ERROR", e.message, null)
                }
            }
            "validateCertificatePinning" -> {
                try {
                    val isValid = keystoreManager.validateCertificatePinningConfig()
                    result.success(isValid)
                } catch (e: Exception) {
                    Log.e("KeystorePlugin", "Error validating certificate pinning", e)
                    result.error("CERT_PINNING_ERROR", e.message, null)
                }
            }
            "validateHostname" -> {
                try {
                    val hostname = call.argument<String>("hostname")
                    if (hostname != null) {
                        val isValid = keystoreManager.validateHostname(hostname)
                        result.success(isValid)
                    } else {
                        result.error("INVALID_ARGUMENT", "Hostname is required", null)
                    }
                } catch (e: Exception) {
                    Log.e("KeystorePlugin", "Error validating hostname", e)
                    result.error("HOSTNAME_ERROR", e.message, null)
                }
            }
            "getCertificateInfo" -> {
                try {
                    val hostname = call.argument<String>("hostname")
                    if (hostname != null) {
                        val certInfo = keystoreManager.getCertificateInfo(hostname)
                        result.success(certInfo)
                    } else {
                        result.error("INVALID_ARGUMENT", "Hostname is required", null)
                    }
                } catch (e: Exception) {
                    Log.e("KeystorePlugin", "Error getting certificate info", e)
                    result.error("CERT_INFO_ERROR", e.message, null)
                }
            }
            "createSecureConnection" -> {
                try {
                    val url = call.argument<String>("url")
                    if (url != null) {
                        val connection = keystoreManager.createSecureConnection(url)
                        result.success(connection != null)
                    } else {
                        result.error("INVALID_ARGUMENT", "URL is required", null)
                    }
                } catch (e: Exception) {
                    Log.e("KeystorePlugin", "Error creating secure connection", e)
                    result.error("CONNECTION_ERROR", e.message, null)
                }
            }
            "updatePinnedCertificates" -> {
                try {
                    val certificates = call.argument<List<String>>("certificates")
                    if (certificates != null) {
                        val updated = keystoreManager.updatePinnedCertificates(certificates.toTypedArray())
                        result.success(updated)
                    } else {
                        result.error("INVALID_ARGUMENT", "Certificates array is required", null)
                    }
                } catch (e: Exception) {
                    Log.e("KeystorePlugin", "Error updating pinned certificates", e)
                    result.error("CERT_UPDATE_ERROR", e.message, null)
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}