# Guide des Services Natifs et Intégration Plateforme - Application Surveillée

## 1. Architecture de communication Flutter-Native

### 1.1 MethodChannel Setup

**Configuration des canaux de communication :**
```
Canaux principaux :
- com.xpsafeconnect.monitored/collectors
- com.xpsafeconnect.monitored/services  
- com.xpsafeconnect.monitored/system
- com.xpsafeconnect.monitored/emergency

Structure des messages :
Request : {
  "method": "startSmsCollection",
  "params": {
    "config": {...}
  }
}

Response : {
  "success": true,
  "data": {...},
  "error": null
}
```

### 1.2 EventChannel pour streaming

**Canaux d'événements temps réel :**
```
Event streams :
- location_updates : GPS continu
- sms_received : Nouveaux SMS
- call_state : État des appels
- battery_status : Changements batterie

Logique d'implémentation :
- Native pousse les events
- Flutter écoute le stream
- Gestion erreurs/completion
- Cancel propre à la destruction
```

## 2. Module Android (Kotlin)

### 2.1 Structure du module natif

**Organisation du code Kotlin :**
```
android/app/src/main/kotlin/com/xpsafeconnect/monitored/
├── MainActivity.kt
├── MainApplication.kt
├── channels/
│   ├── CollectorMethodChannel.kt
│   ├── ServiceMethodChannel.kt
│   └── SystemMethodChannel.kt
├── collectors/
│   ├── BaseCollector.kt
│   ├── SmsCollector.kt
│   ├── CallCollector.kt
│   ├── LocationCollector.kt
│   ├── AppUsageCollector.kt
│   └── MediaCollector.kt
├── services/
│   ├── BackgroundService.kt
│   ├── BootReceiver.kt
│   ├── ScreenshotService.kt
│   └── AccessibilityService.kt
├── utils/
│   ├── PermissionHelper.kt
│   ├── NotificationHelper.kt
│   └── DeviceInfoHelper.kt
└── security/
    ├── RootDetector.kt
    └── AntiTamper.kt
```

### 2.2 SMS Collector natif

**SmsCollector.kt - Logique d'implémentation :**
```kotlin
Fonctionnalités :
- ContentObserver sur SMS provider
- Lecture via ContentResolver  
- Filtrage par date/type
- Extraction métadonnées complètes
- Support MMS basique

Implémentation ContentObserver :
class SmsObserver : ContentObserver {
  override fun onChange() {
    // 1. Query new messages
    // 2. Filter already processed
    // 3. Extract all fields
    // 4. Convert to Flutter format
    // 5. Send via EventChannel
  }
}

Permissions requises :
- READ_SMS
- RECEIVE_SMS (pour temps réel)
- READ_PHONE_STATE
```

### 2.3 Call Logger natif

**CallCollector.kt - Logique :**
```kotlin
Monitoring des appels :
- PhoneStateListener pour temps réel
- CallLog.Calls pour historique
- Enrichissement avec contacts
- Durée précise des appels

États d'appel gérés :
- RINGING : Appel entrant
- OFFHOOK : Décroché
- IDLE : Raccroché

Données extraites :
- Number (peut être masqué)
- Duration en secondes
- Type (IN/OUT/MISSED)
- Contact name si disponible
- Timestamp précis
- SIM slot si dual SIM
```

### 2.4 Location Service natif

**LocationCollector.kt - Logique avancée :**
```kotlin
FusedLocationProvider setup :
- Priority dynamique
- Interval adaptatif
- Geofencing intégré
- Activity recognition

Optimisations batterie :
fun adaptLocationUpdates(batteryLevel: Int) {
  when {
    batteryLevel > 50 -> highAccuracyMode()
    batteryLevel > 30 -> balancedMode()
    batteryLevel > 15 -> lowPowerMode()
    else -> emergencyOnlyMode()
  }
}

Données enrichies :
- Latitude/Longitude/Altitude
- Accuracy/Speed/Bearing
- Provider (GPS/Network/Fused)
- Activity (Still/Walking/Driving)
- Nearby WiFi/Cell towers
```

### 2.5 Screenshot Service

**ScreenshotService.kt - MediaProjection :**
```kotlin
Capture d'écran implementation :
1. Request MediaProjection permission
2. Create VirtualDisplay
3. Setup ImageReader
4. Capture on demand/schedule
5. Compress to JPEG
6. Send to Flutter

Optimisations :
- Réutiliser MediaProjection
- Buffer unique ImageReader
- Compression adaptative
- Résolution réduite si batterie faible
- Cleanup après capture

Notification obligatoire :
- "Service actif" minimum
- Icône discrète possible
- Channel importance LOW
```

### 2.6 Accessibility Service

**MonitoringAccessibilityService.kt :**
```kotlin
Surveillance WhatsApp/Messageries :
override fun onAccessibilityEvent(event: AccessibilityEvent) {
  when(event.packageName) {
    "com.whatsapp" -> handleWhatsApp(event)
    "com.facebook.orca" -> handleMessenger(event)
    // Autres apps...
  }
}

Extraction données :
- Type d'événement UI
- Textes visibles
- Timestamps
- Contexte (conversation, contact)

Limitations :
- Dépend de la structure UI
- Peut casser avec updates
- Performance impact
- Données partielles
```

### 2.7 Background Service principal

**BackgroundService.kt - ForegroundService :**
```kotlin
Service lifecycle :
- START_STICKY pour persistence
- Notification permanente
- WakeLock si nécessaire
- WorkManager pour periodic tasks

Orchestration :
class BackgroundService : Service() {
  private val collectors = mutableListOf<BaseCollector>()
  
  override fun onStartCommand() {
    startForeground(NOTIFICATION_ID, createNotification())
    initializeCollectors()
    schedulePeriodicSync()
    return START_STICKY
  }
  
  private fun handleBatteryOptimization() {
    // Adapter tous les collectors
    // Selon niveau batterie
  }
}

Redémarrage après kill :
- BootReceiver
- AlarmManager backup
- JobScheduler resilient
- Multiple stratégies
```

### 2.8 Protection système

**AntiTamper.kt - Sécurité :**
```kotlin
Vérifications sécurité :
fun performSecurityChecks(): SecurityStatus {
  return SecurityStatus(
    isRooted = checkRoot(),
    isDebuggable = checkDebugging(),
    isEmulator = checkEmulator(),
    signatureValid = verifySignature(),
    isHooked = checkHooks()
  )
}

Root detection :
- Check su binary
- Test-keys build
- Busybox present
- Root apps installed
- System properties

Actions si compromis :
- Log et notification serveur
- Mode dégradé
- Pas de données sensibles
```

## 3. Module iOS (Swift)

### 3.1 Structure du module iOS

**Organisation du code Swift :**
```
ios/Runner/
├── AppDelegate.swift
├── Channels/
│   ├── CollectorChannel.swift
│   └── ServiceChannel.swift
├── Collectors/
│   ├── LocationCollector.swift
│   └── DeviceInfoCollector.swift
├── Services/
│   ├── BackgroundTaskService.swift
│   └── NotificationService.swift
└── Utils/
    ├── PermissionManager.swift
    └── SecurityChecker.swift
```

### 3.2 Location Collector iOS

**LocationCollector.swift - Logique :**
```swift
CLLocationManager configuration :
- requestAlwaysAuthorization obligatoire
- allowsBackgroundLocationUpdates = true
- pausesLocationUpdatesAutomatically = false
- desiredAccuracy adaptatif

Modes de tracking :
1. Continuous : High accuracy
2. Significant : Battery saving
3. Region : Geofencing
4. Visit : Lieux fréquentés

Background constraints :
- Blue bar si continuous
- Limited time execution
- Must show purpose
- User can restrict
```

### 3.3 Background Tasks iOS

**BackgroundTaskService.swift :**
```swift
BGTaskScheduler usage :
- Register tasks in Info.plist
- Schedule periodic refresh
- Handle in AppDelegate
- Limited execution time

Stratégies background :
1. BGAppRefreshTask : Sync périodique
2. BGProcessingTask : Tâches longues
3. Silent Push : Réveil à distance
4. Location updates : Maintien continu

Exemple scheduling :
func scheduleAppRefresh() {
  let request = BGAppRefreshTaskRequest(
    identifier: "com.xpsafeconnect.sync"
  )
  request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
  BGTaskScheduler.shared.submit(request)
}
```

### 3.4 Limitations iOS

**Contraintes système strictes :**
```
Impossible sur iOS :
- Accès SMS/Calls
- Screenshots
- Surveillance apps tierces
- Accès fichiers système
- Modification système

Compensations :
- Focus sur localisation
- Notifications créatives
- Geofencing intensif
- Educate users
- MDM si entreprise
```

## 4. Optimisations natives

### 4.1 Battery optimizations Android

**Logique d'économie d'énergie :**
```kotlin
PowerManager integration :
- Detect Doze mode
- Request exemption prudente
- Adapt behavior in Doze
- Use JobScheduler

Doze mode handling :
fun isInDozeMode(): Boolean {
  val pm = getSystemService(PowerManager::class.java)
  return pm.isDeviceIdleMode
}

Stratégies :
- Batch network requests
- Defer non-critical ops
- Use passive location
- Reduce wake frequency
```

### 4.2 Memory management

**Gestion mémoire native :**
```kotlin
Optimisations mémoire :
- Object pooling pour buffers
- Weak references si approprié
- Clear caches régulièrement
- Profile avec LeakCanary

Exemple pool :
object BitmapPool {
  private val pool = LinkedList<Bitmap>()
  
  fun obtain(width: Int, height: Int): Bitmap {
    return pool.poll() 
      ?: Bitmap.createBitmap(width, height, Config.RGB_565)
  }
  
  fun recycle(bitmap: Bitmap) {
    if (pool.size < MAX_POOL_SIZE) {
      pool.offer(bitmap)
    }
  }
}
```

## 5. Communication bidirectionnelle

### 5.1 Flutter vers Native

**Appels de méthodes :**
```dart
// Côté Flutter
final result = await platform.invokeMethod('startSmsCollection', {
  'config': {
    'includeOutgoing': true,
    'keywords': ['urgent', 'help'],
    'maxAge': 7 * 24 * 60 * 60 * 1000, // 7 jours
  }
});

// Côté Android (Kotlin)
when (call.method) {
  "startSmsCollection" -> {
    val config = call.argument<Map<String, Any>>("config")
    smsCollector.start(config)
    result.success(true)
  }
}
```

### 5.2 Native vers Flutter

**Events streaming :**
```kotlin
// Côté Android
private val eventSink: EventChannel.EventSink? = null

fun sendSmsUpdate(sms: SmsData) {
  eventSink?.success(mapOf(
    "type" to "sms_received",
    "data" to sms.toMap()
  ))
}

// Côté Flutter  
_smsStream = EventChannel('sms_events')
  .receiveBroadcastStream()
  .listen((event) {
    final sms = SmsModel.fromMap(event['data']);
    _handleNewSms(sms);
  });
```

## 6. Tests des modules natifs

### 6.1 Tests unitaires Android

**Structure de tests Kotlin :**
```kotlin
Tests essentiels :
- Permission checks
- Data extraction
- Security validations
- Service lifecycle

Exemple test :
@Test
fun testSmsExtraction() {
  val cursor = mockCursor(smsData)
  val messages = smsCollector.extractMessages(cursor)
  
  assertEquals(10, messages.size)
  assertEquals("Test message", messages[0].body)
}

Mocking :
- Mockito pour Android
- Robolectric pour Context
- MockK pour Kotlin
```

### 6.2 Tests d'intégration

**Tests bout en bout :**
```
Scénarios critiques :
1. Service survit au kill
2. Collecte continue 24h
3. Sync après reconnexion
4. Battery drain acceptable
5. Memory stable

Outils :
- Espresso pour UI
- UIAutomator pour système
- ADB commands
- Battery Historian
```

## 7. Debugging natif

### 7.1 Logs structurés

**Logging strategy :**
```kotlin
object Logger {
  fun d(tag: String, message: String) {
    if (BuildConfig.DEBUG) {
      Log.d(tag, sanitize(message))
    }
  }
  
  private fun sanitize(message: String): String {
    // Remove sensitive data
    return message
      .replace(Regex("\\d{10,}"), "[PHONE]")
      .replace(Regex("\\b\\d{4,}\\b"), "[NUMBER]")
  }
}
```

### 7.2 Profiling tools

**Outils de profiling :**
```
Android Studio :
- CPU Profiler
- Memory Profiler
- Network Profiler
- Energy Profiler

Commandes ADB :
- dumpsys battery
- dumpsys cpuinfo
- dumpsys meminfo
- logcat filtering
```

## 8. Distribution des modules

### 8.1 Configuration build

**Build variants Android :**
```gradle
buildTypes {
  debug {
    minifyEnabled false
    debuggable true
  }
  release {
    minifyEnabled true
    proguardFiles 'proguard-rules.pro'
    ndk {
      debugSymbolLevel 'FULL'
    }
  }
}

Configuration ProGuard :
- Keep native methods
- Keep JNI interfaces
- Obfuscate helpers
- Strip logs
```

### 8.2 Symbols et crash reports

**Gestion des symboles :**
```
Android :
- Upload to Crashlytics
- Keep mapping files
- NDK symbols if used

iOS :
- dSYM files required
- Upload to services
- Bitcode considerations
```

## 9. Évolutions futures

### 9.1 Nouvelles APIs Android

**APIs à surveiller :**
```
Android 14+ :
- Enhanced background limits
- New permission model
- Privacy dashboard impact
- Data access auditing

Préparation :
- Suivre Android Beta
- Tester sur preview
- Adapter strategies
- User communication
```

### 9.2 Améliorations iOS

**Possibilités futures :**
```
Espoirs iOS :
- Background améliré
- APIs surveillance (improbable)
- MDM features
- Enterprise options

Réaliste :
- Location plus flexible
- Background tasks extended
- Widgets informatifs
- Shortcuts/Intents
```