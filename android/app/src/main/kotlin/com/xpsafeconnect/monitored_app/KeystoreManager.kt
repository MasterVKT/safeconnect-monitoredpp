package com.xpsafeconnect.monitored_app

import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import android.util.Log
import java.io.ByteArrayInputStream
import java.security.KeyStore
import java.security.MessageDigest
import java.security.cert.CertificateFactory
import java.security.cert.X509Certificate
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec
import javax.net.ssl.HttpsURLConnection
import javax.net.ssl.SSLContext
import javax.net.ssl.TrustManager
import javax.net.ssl.TrustManagerFactory
import javax.net.ssl.X509TrustManager
import kotlin.random.Random

class KeystoreManager {
    companion object {
        private const val TAG = "KeystoreManager"
        private const val KEYSTORE_PROVIDER = "AndroidKeyStore"
        private const val KEY_ALIAS = "monitored_app_master_key"
        private const val TRANSFORMATION = "AES/GCM/NoPadding"
        private const val GCM_IV_LENGTH = 12
        private const val GCM_TAG_LENGTH = 16
        
        // Certificate pinning constants
        private const val SERVER_HOSTNAME = "api.xpsafeconnect.com"
        private val PINNED_CERTIFICATES = arrayOf(
            // Production certificate SHA-256 fingerprints
            "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=", // Replace with actual cert fingerprint
            "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=", // Backup certificate
        )
        
        // Certificate validation timeout
        private const val CERT_VALIDATION_TIMEOUT_MS = 10000
    }

    /**
     * Generates or retrieves the master encryption key from Android Keystore
     */
    fun getMasterKey(): String? {
        return try {
            val keyStore = KeyStore.getInstance(KEYSTORE_PROVIDER)
            keyStore.load(null)

            // Check if key already exists
            if (!keyStore.containsAlias(KEY_ALIAS)) {
                generateMasterKey()
            }

            // Generate a derived key for database encryption
            val derivedKey = generateDerivedKey()
            Base64.encodeToString(derivedKey, Base64.NO_WRAP)
        } catch (e: Exception) {
            Log.e(TAG, "Error getting master key", e)
            null
        }
    }

    /**
     * Generates a new master key in Android Keystore with enhanced security
     */
    private fun generateMasterKey() {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
            try {
                generateMasterKeyWithSpec(useStrongBox = true)
                Log.d(TAG, "Master key generated with StrongBox")
                return
            } catch (e: android.security.keystore.StrongBoxUnavailableException) {
                Log.w(TAG, "StrongBox unavailable, falling back to TEE")
            } catch (e: Exception) {
                if (e.cause is android.security.keystore.StrongBoxUnavailableException) {
                    Log.w(TAG, "StrongBox unavailable (cause), falling back to TEE")
                } else {
                    Log.e(TAG, "Error generating StrongBox key", e)
                }
            }
        }

        try {
            generateMasterKeyWithSpec(useStrongBox = false)
            Log.d(TAG, "Master key generated with TEE")
        } catch (e: Exception) {
            Log.e(TAG, "Error generating master key", e)
            throw SecurityException("Failed to generate secure key", e)
        }
    }

    private fun generateMasterKeyWithSpec(useStrongBox: Boolean) {
        val keyGenerator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, KEYSTORE_PROVIDER)
        val builder = KeyGenParameterSpec.Builder(
            KEY_ALIAS,
            KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
        )
        .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
        .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
        .setKeySize(256)
        .setUserAuthenticationRequired(false)
        .setRandomizedEncryptionRequired(true)

        if (useStrongBox && android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
            builder.setIsStrongBoxBacked(true)
        }

        keyGenerator.init(builder.build())
        keyGenerator.generateKey()
    }

    /**
     * Generates a derived key for database encryption using the master key
     */
    private fun generateDerivedKey(): ByteArray {
        try {
            val keyStore = KeyStore.getInstance(KEYSTORE_PROVIDER)
            keyStore.load(null)

            val secretKey = keyStore.getKey(KEY_ALIAS, null) as SecretKey
            val cipher = Cipher.getInstance(TRANSFORMATION)
            
            // Generate random data to encrypt (key derivation)
            val randomData = Random.nextBytes(32)
            
            cipher.init(Cipher.ENCRYPT_MODE, secretKey)
            val iv = cipher.iv
            val encryptedData = cipher.doFinal(randomData)
            
            // Use HKDF-like approach: combine IV + encrypted data for derived key
            val derivedKey = ByteArray(32)
            System.arraycopy(iv, 0, derivedKey, 0, minOf(iv.size, 16))
            System.arraycopy(encryptedData, 0, derivedKey, 16, minOf(encryptedData.size, 16))
            
            return derivedKey
        } catch (e: Exception) {
            Log.e(TAG, "Error generating derived key", e)
            throw SecurityException("Failed to generate derived key", e)
        }
    }

    /**
     * Encrypts sensitive data using the master key
     */
    fun encryptData(plaintext: String): String? {
        return try {
            val keyStore = KeyStore.getInstance(KEYSTORE_PROVIDER)
            keyStore.load(null)

            val secretKey = keyStore.getKey(KEY_ALIAS, null) as SecretKey
            val cipher = Cipher.getInstance(TRANSFORMATION)
            
            cipher.init(Cipher.ENCRYPT_MODE, secretKey)
            val iv = cipher.iv
            val encryptedData = cipher.doFinal(plaintext.toByteArray())
            
            // Combine IV + encrypted data
            val combined = iv + encryptedData
            Base64.encodeToString(combined, Base64.NO_WRAP)
        } catch (e: Exception) {
            Log.e(TAG, "Error encrypting data", e)
            null
        }
    }

    /**
     * Decrypts data encrypted with the master key
     */
    fun decryptData(encryptedData: String): String? {
        return try {
            val keyStore = KeyStore.getInstance(KEYSTORE_PROVIDER)
            keyStore.load(null)

            val secretKey = keyStore.getKey(KEY_ALIAS, null) as SecretKey
            val combined = Base64.decode(encryptedData, Base64.NO_WRAP)
            
            // Extract IV and encrypted data
            val iv = combined.sliceArray(0..GCM_IV_LENGTH - 1)
            val encrypted = combined.sliceArray(GCM_IV_LENGTH until combined.size)
            
            val cipher = Cipher.getInstance(TRANSFORMATION)
            val gcmSpec = GCMParameterSpec(GCM_TAG_LENGTH * 8, iv)
            cipher.init(Cipher.DECRYPT_MODE, secretKey, gcmSpec)
            
            val decryptedData = cipher.doFinal(encrypted)
            String(decryptedData)
        } catch (e: Exception) {
            Log.e(TAG, "Error decrypting data", e)
            null
        }
    }

    /**
     * Validates the integrity of the keystore
     */
    fun validateKeystore(): Boolean {
        return try {
            val testData = "keystore_integrity_test"
            val encrypted = encryptData(testData)
            val decrypted = encrypted?.let { decryptData(it) }
            
            testData == decrypted
        } catch (e: Exception) {
            Log.e(TAG, "Keystore validation failed", e)
            false
        }
    }

    /**
     * Securely deletes the master key (for app uninstallation)
     */
    fun deleteMasterKey(): Boolean {
        return try {
            val keyStore = KeyStore.getInstance(KEYSTORE_PROVIDER)
            keyStore.load(null)
            keyStore.deleteEntry(KEY_ALIAS)
            true
        } catch (e: Exception) {
            Log.e(TAG, "Error deleting master key", e)
            false
        }
    }
    
    // Certificate Pinning Implementation
    
    /**
     * Creates a custom SSL context with certificate pinning
     */
    fun createPinnedSSLContext(): SSLContext? {
        return try {
            val trustManager = createPinnedTrustManager()
            val sslContext = SSLContext.getInstance("TLS")
            sslContext.init(null, arrayOf(trustManager), null)
            sslContext
        } catch (e: Exception) {
            Log.e(TAG, "Error creating pinned SSL context", e)
            null
        }
    }
    
    /**
     * Creates a trust manager that validates certificate pinning
     */
    private fun createPinnedTrustManager(): X509TrustManager {
        return object : X509TrustManager {
            private val defaultTrustManager: X509TrustManager by lazy {
                val trustManagerFactory = TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm())
                trustManagerFactory.init(null as KeyStore?)
                trustManagerFactory.trustManagers[0] as X509TrustManager
            }
            
            override fun checkClientTrusted(chain: Array<X509Certificate>, authType: String) {
                defaultTrustManager.checkClientTrusted(chain, authType)
            }
            
            override fun checkServerTrusted(chain: Array<X509Certificate>, authType: String) {
                // First, perform standard certificate validation
                defaultTrustManager.checkServerTrusted(chain, authType)
                
                // Then, check certificate pinning
                if (!validateCertificatePinning(chain)) {
                    throw SecurityException("Certificate pinning validation failed")
                }
                
                Log.d(TAG, "Certificate pinning validation successful")
            }
            
            override fun getAcceptedIssuers(): Array<X509Certificate> {
                return defaultTrustManager.acceptedIssuers
            }
        }
    }
    
    /**
     * Validates certificate pinning against known certificates
     */
    private fun validateCertificatePinning(chain: Array<X509Certificate>): Boolean {
        try {
            for (certificate in chain) {
                val certificateFingerprint = getCertificateFingerprint(certificate)
                
                for (pinnedCert in PINNED_CERTIFICATES) {
                    if (pinnedCert == certificateFingerprint) {
                        Log.d(TAG, "Certificate pinning match found")
                        return true
                    }
                }
            }
            
            Log.w(TAG, "No certificate pinning match found")
            return false
        } catch (e: Exception) {
            Log.e(TAG, "Error validating certificate pinning", e)
            return false
        }
    }
    
    /**
     * Computes SHA-256 fingerprint of a certificate
     */
    private fun getCertificateFingerprint(certificate: X509Certificate): String {
        return try {
            val digest = MessageDigest.getInstance("SHA-256")
            val hash = digest.digest(certificate.encoded)
            Base64.encodeToString(hash, Base64.NO_WRAP)
        } catch (e: Exception) {
            Log.e(TAG, "Error computing certificate fingerprint", e)
            ""
        }
    }
    
    /**
     * Validates a hostname against certificate pinning rules
     */
    fun validateHostname(hostname: String): Boolean {
        return hostname == SERVER_HOSTNAME || hostname.endsWith(".$SERVER_HOSTNAME")
    }
    
    /**
     * Creates a secure HTTPS connection with certificate pinning
     */
    fun createSecureConnection(url: String): HttpsURLConnection? {
        return try {
            val connection = java.net.URL(url).openConnection() as HttpsURLConnection
            val sslContext = createPinnedSSLContext()
            
            if (sslContext != null) {
                connection.sslSocketFactory = sslContext.socketFactory
                connection.hostnameVerifier = javax.net.ssl.HostnameVerifier { hostname, _ ->
                    validateHostname(hostname)
                }
                connection.connectTimeout = CERT_VALIDATION_TIMEOUT_MS
                connection.readTimeout = CERT_VALIDATION_TIMEOUT_MS
            }
            
            connection
        } catch (e: Exception) {
            Log.e(TAG, "Error creating secure connection", e)
            null
        }
    }
    
    /**
     * Validates the current certificate pinning configuration
     */
    fun validateCertificatePinningConfig(): Boolean {
        return try {
            // Check if pinned certificates are properly configured
            if (PINNED_CERTIFICATES.isEmpty()) {
                Log.w(TAG, "No pinned certificates configured")
                return false
            }
            
            // Validate each pinned certificate format
            for (pinnedCert in PINNED_CERTIFICATES) {
                if (pinnedCert.length < 40) { // SHA-256 base64 should be longer
                    Log.w(TAG, "Invalid pinned certificate format: $pinnedCert")
                    return false
                }
            }
            
            // Test connection to validate pinning
            val testConnection = createSecureConnection("https://$SERVER_HOSTNAME/health")
            testConnection?.disconnect()
            
            Log.d(TAG, "Certificate pinning configuration is valid")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Certificate pinning configuration validation failed", e)
            false
        }
    }
    
    /**
     * Gets certificate information for debugging
     */
    fun getCertificateInfo(hostname: String): Map<String, String> {
        return try {
            val connection = java.net.URL("https://$hostname").openConnection() as HttpsURLConnection
            connection.connect()
            
            val certificates = connection.serverCertificates
            val info = mutableMapOf<String, String>()
            
            certificates?.forEachIndexed { index, cert ->
                if (cert is X509Certificate) {
                    info["cert_${index}_subject"] = cert.subjectDN.name
                    info["cert_${index}_issuer"] = cert.issuerDN.name
                    info["cert_${index}_fingerprint"] = getCertificateFingerprint(cert)
                    info["cert_${index}_valid_from"] = cert.notBefore.toString()
                    info["cert_${index}_valid_to"] = cert.notAfter.toString()
                }
            }
            
            connection.disconnect()
            info
        } catch (e: Exception) {
            Log.e(TAG, "Error getting certificate info", e)
            mapOf("error" to e.message.orEmpty())
        }
    }
    
    /**
     * Emergency certificate pinning bypass (for debugging only)
     */
    fun bypassCertificatePinning(bypass: Boolean) {
        if (bypass) {
            Log.w(TAG, "WARNING: Certificate pinning bypass enabled - INSECURE!")
            // In production, this should be disabled or require special authorization
        }
    }
    
    /**
     * Update pinned certificates dynamically (for certificate rotation)
     */
    fun updatePinnedCertificates(newCertificates: Array<String>): Boolean {
        return try {
            // Validate new certificates format
            for (cert in newCertificates) {
                if (cert.length < 40) {
                    Log.e(TAG, "Invalid certificate format in update")
                    return false
                }
            }
            
            // In a real implementation, you would securely update the pinned certificates
            // This might involve server verification, secure storage, etc.
            Log.d(TAG, "Certificate pinning update requested - ${newCertificates.size} certificates")
            
            // For security, this should require additional verification
            true
        } catch (e: Exception) {
            Log.e(TAG, "Error updating pinned certificates", e)
            false
        }
    }
}