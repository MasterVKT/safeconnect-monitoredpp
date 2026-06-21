# Logs Application Surveillée — Version Épurée

> **Source** : `flutter run --dart-define=API_BASE_URL=http://192.168.1.127:8000` sur **HONOR GFY-LX2** (Android 14, API 34)  
> **Date** : 2026-06-10  
> **Objectif** : Analyse des problèmes d'accès et d'affichage des données (SMS, Medias, Appels, Apps, Localisation) dans l'application surveillante

---

## 1. Build & Lancement

```
Connected devices:
GFY LX2 (mobile)  ● A2SJCP4A19414110 ● android-arm64 ● Android 14 (API 34)

Launching lib\main.dart on GFY LX2 in debug mode...
Running Gradle task 'assembleDebug'...
Generating security hashes...
Security hashes generated.
Validating build security configuration...
Build security validation completed.
Running Gradle task 'assembleDebug'... 42,3s
✓ Built build\app\outputs\flutter-apk\app-debug.apk
Installing build\app\outputs\flutter-apk\app-debug.apk... 18,1s
```

---

## 2. Initialisation de l'Application (Flutter/Dart)

```
I/flutter: AppConfig initialized: env=dev, api=http://192.168.1.127:8000/api/v1, displayMode=NORMAL
I/flutter: Database initialized with encryption
I/flutter: Skipping SecurityService.initialize() in debug mode
I/flutter: Skipping EmergencyService.initialize() in debug mode
I/flutter: Skipping StealthService.initialize() in debug mode
I/flutter: Skipping AntiTamperService.initialize() in debug mode
I/flutter: Media scheduler started
I/flutter: Bandwidth optimization started
I/flutter: Advanced Media Service initialized successfully
I/flutter: Skipping RASPService.initialize() in debug mode
I/flutter: Skipping SecurityMonitoringService.initialize() in debug mode
I/flutter: BatteryMonitorService initialized
I/flutter: Initializing Performance Optimizer...
I/flutter: Loaded performance configuration: mode=balanced, strategy=moderate
I/flutter: Setup 5 optimization rules
I/flutter: Performance Optimizer initialized
I/flutter: SyncStatusMonitor initialized
I/flutter: Sync status updated: idle
I/flutter: DeviceService initialization skipped: no authenticated session yet
I/flutter: PerformanceMonitor initialized
I/flutter: ConsentManager initialized with 0 active consents
I/flutter: P2P Communication Service initialized
I/flutter: P2P Signaling Service initialized
I/flutter: P2P Command Handler initialized
I/flutter: Loaded 4 ICE servers
I/flutter: WebRTC initialized for platform: android
I/flutter: WebRTC metrics collection started
I/flutter: WebRTC heartbeat started
I/flutter: WebSocket: Handler added for message type: webrtc_signaling
I/flutter: WebSocket: Handler added for message type: peer_connection_request
I/flutter: WebSocket handlers setup for WebRTC signaling
I/flutter: Production WebRTC Service initialized successfully
I/flutter: P2P Manager state changed to: P2PManagerState.initializing
I/flutter: P2P Manager state changed to: P2PManagerState.ready
I/flutter: P2P Manager initialized successfully
I/flutter: Initializing P2P File Transfer Service...
I/flutter: Temp directory setup: /data/user/0/com.xpsafeconnect.monitored_app/code_cache/monitored_app_transfers
I/flutter: File transfer message handlers setup
I/flutter: Loaded 0 pending file transfer sessions
I/flutter: P2P File Transfer Service initialized
I/flutter: TestValidationService initialized successfully
```

---

## 3. Jumelage (Pairing)

```
I/flutter: Starting device pairing with code: 554885
I/flutter: [PAIRING] Starting device pairing process...
I/flutter: [PAIRING] Calling validate-pairing-code endpoint...
I/flutter: REQUEST[POST] => http://192.168.1.127:8000/api/v1/devices/validate-pairing-code/
I/flutter: DATA => {pairing_code: 554885, pairingCode: 554885, device_identifier: HONORGFY-L32, device_info: {platform: ANDROID, device_name: HONOR GFY-LX2, model: GFY-LX2, device_model: HONOR GFY-LX2, manufacturer: HONOR, device_id: HONORGFY-L32, os_version: 14, sdk_version: 34, app_version: 1.0.0-debug, app_build_number: 1}, deviceInfo: {platform: ANDROID, device_name: HONOR GFY-LX2, model: GFY-LX2, device_model: HONOR GFY-LX2, manufacturer: HONOR, device_id: HONORGFY-L32, os_version: 14, sdk_version: 34, app_version: 1.0.0-debug, app_build_number: 1}}
I/flutter: RESPONSE[200] => http://192.168.1.127:8000/api/v1/devices/validate-pairing-code/
I/flutter: DATA => {success: true, message: Jumelage réussi, device_id: 9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721, device: {id: 9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721, name: HONOR GFY-LX2, device_name: HONOR GFY-LX2, device_identifier: HONORGFY-L32, platform: ANDROID, model: HONOR GFY-LX2, device_model: HONOR GFY-LX2, os_version: 14, is_monitored: true, is_monitoring: false, last_seen: 2026-06-10T18:57:30.024245Z, last_sync: 2026-06-10T18:57:30.024245Z, is_online: false, battery_level: null, is_charging: false, created_at: 2026-06-07T02:41:52.318902Z, updated_at: 2026-06-10T18:55:59.564041Z, user: {id: 1c1261a0-819e-49c1-a236-48d7c03aa942, email: ericvekout@gmail.com, full_name: Eric Vekout}, status: OFFLINE, monitored_by: [{device_id: 29aeccd6-dd5f-48ba-93ef-373ae07ba4e6, device_name: Mon appareil (en cours de jumelage), user: {id: 1c1261a0-819e-49c1-a236-48d7c03aa942, email: ericvekout@gmail.com, full_name: Eric Vekout}, permission_type: FULL_ACCESS, granted_at: 2026-06-10T19:18:59.971135+00:00}], monitoring: [], display_mode: NORMAL, fcm_token_registered: false}}
I/flutter: [PAIRING] Received response: 200
I/flutter: [PAIRING] Parsing auth response...
I/flutter: [PAIRING] Auth response parsed successfully
I/flutter: [PAIRING] Storing auth data...
I/flutter: [PAIRING] Storing paired device ID: 9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721
I/flutter: [PAIRING] Connecting WebSocket...
I/flutter: WebSocket: Connecting with deviceId=9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721
I/flutter: WebSocket: Connected
I/flutter: [PAIRING] Starting DeviceService in background...
I/flutter: [PAIRING] Starting token refresh...
I/flutter: [PAIRING] Logging security event...
I/flutter: [PAIRING] Skipping security event log - not initialized
I/flutter: [PAIRING] Pairing completed successfully!
I/flutter: [PAIRING] Triggering initial full data sync with new auth tokens...
I/flutter: Device pairing successful
```

---

## 4. Statut des Permissions (avant et après accord)

### 4.1 — Permissions NON accordées (première initialisation des collecteurs)

```
I/flutter: [DataCollector] Stopping prior collectors due to permission change
I/flutter: [DataCollector] stopCollectors() skipped: collectors not running
I/flutter: [DataCollector] Restarting collectors after permission change
I/flutter: No pending sync items found in database
I/flutter: No server configuration available, using defaults

I/flutter: Initializing SMS collector
I/flutter: SMS: Required permissions not granted
I/flutter: [SMS] initialized with bootstrapPending=true, lastCheckTime=null
I/flutter: SMS collector initialized successfully

I/flutter: Initializing Calls collector
I/flutter: Calls: Required permissions not granted
I/flutter: [Calls] initialized with bootstrapPending=true, lastCheckTime=null
I/flutter: Calls collector initialized successfully

I/flutter: Initializing Location collector
I/flutter: Location: Required permissions not granted
I/flutter: Location collector initialized successfully

I/flutter: Initializing Apps collector
I/flutter: Apps: Required permissions not granted
I/flutter: Apps collector specific initialization completed
I/flutter: Apps collector initialized successfully

I/flutter: Camera or storage permissions not granted
I/flutter: [MediaStore] initialized with per-category bootstrap checkpoints

I/flutter: SMS: Cannot start collection - permissions not granted
I/flutter: Calls: Cannot start collection - permissions not granted
I/flutter: Location: Cannot start collection - permissions not granted
I/flutter: Apps: Cannot start collection - permissions not granted
I/flutter: [MEDIA] Cannot start media collection: permissions not granted
I/flutter: [MediaStore] Cannot start scan: media read permissions missing
I/flutter: [DataCollector] Sync: isSyncing=false, queueEmpty=true
```

### 4.2 — Configuration de collecte serveur reçue

```
I/flutter: REQUEST[GET] => http://192.168.1.127:8000/api/v1/data/collection-config/?device_id=9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721
I/flutter: DATA => null

I/flutter: REQUEST[GET] => http://192.168.1.127:8000/api/v1/data/collection-config/?device_id=9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721
I/flutter: RESPONSE[200] => http://192.168.1.127:8000/api/v1/data/collection-config/?device_id=9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721
I/flutter: DATA => {location: {enabled: true, interval_seconds: 900, accuracy: BALANCED}, messages: {enabled: true, types: [SMS, MMS, WHATSAPP, TELEGRAM, MESSENGER], include_content: true}, calls: {enabled: true, record_calls: false}, app_usage: {enabled: true, interval_minutes: 30}, media: {enabled: true, scan_interval_hours: 24, include_thumbnails: false}}
I/flutter: Collection configuration loaded: (location, messages, calls, app_usage, media)
```

### 4.3 — Permissions accordées (après activation dans les réglages Android)

```
I/flutter: [DataCollector] Stopping prior collectors due to permission change
I/flutter: [DataCollector] stopCollectors() skipped: collectors not running
I/flutter: [DataCollector] Restarting collectors after permission change
I/flutter: SMS specific collection started
I/flutter: SMS collector started with interval: 900 seconds
```

### 4.4 — Rapport de permissions au serveur (PATCH device status)

```
I/flutter: REQUEST[PATCH] => http://192.168.1.127:8000/api/v1/devices/devices/9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721/
I/flutter: DATA => {battery_level: 100, is_charging: true, is_online: true, last_sync: 2026-06-10T20:20:38.887393, storage_available: 1073741824, network_type: wifi, location_enabled: true, permissions_status: {location: denied, camera: granted, microphone: granted, contacts: granted, sms: granted, call_log: granted, storage: granted, media_images: granted, media_video: granted, media_audio: granted}, app_version: 1.0.0-debug, os_version: 14, device_model: HONOR GFY-LX2, device_name: HONOR GFY-LX2}
```

> **⚠️ Note importante** : `location: denied` alors que `location_enabled: true`. La permission de localisation n'est pas accordée même si le service de localisation est activé sur l'appareil.

---

## 5. Collecte des Données — Détails par Type

### 5.1 — SMS

```
I/flutter: SMS specific collection started
I/flutter: SMS collector started with interval: 900 seconds
I/flutter: [SMS] Collection skipped: another collection is running
D/SmsCollectorPlugin: getNewSms query returned 65 rows since 1773343219158
I/flutter: [SMS] getNewSms returned 65 entries since 2026-03-12 20:20:19.158602 (bootstrap=true)
I/flutter: Queued sms data for sync with priority 1  (×65 occurrences, une par entrée)
I/flutter: [SMS] Bootstrap completed: 65 historical SMS captured.
I/flutter: SMS: Processed 65 items
I/flutter: SMS periodic check complete: 65 new messages
```

### 5.2 — Appels

```
I/flutter: Calls specific collection started
I/flutter: Calls collector started with interval: 900 seconds
I/flutter: [Calls] Collection skipped: another collection is running
I/flutter: [Calls] getNewCalls returned 51 entries since 2026-03-12 20:20:20.067173 (bootstrap=true)
I/flutter: Queued calls data for sync with priority 2  (×51 occurrences, une par entrée)
I/flutter: [Calls] Bootstrap completed: 51 historical calls captured.
I/flutter: Calls: Processed 51 items
I/flutter: Calls periodic check complete: 51 new calls
```

### 5.3 — Localisation

```
I/flutter: Location specific collection started with interval: 900 seconds
I/flutter: Location collector started with interval: 900 seconds
E/FlutterGeolocator: Geolocator position updates started
I/flutter: Queued location data for sync with priority 2  (×6 occurrences)
I/flutter: Location: Processed 1 items
I/flutter: Location: Processed 1 items
I/flutter: Location: Processed 1 items
```

> **⚠️ Observation** : La collecte de localisation a démarré malgré `location: denied` dans le rapport de permissions. 6 points de localisation ont été collectés (3 appels à "Processed 1 items", soit 3 positions distinctes).

### 5.4 — Apps installées

```
I/flutter: Apps specific collection started
I/flutter: Apps collector started with interval: 900 seconds
I/flutter: Queued app_info data for sync with priority 3  (×158 occurrences)
I/flutter: Collected and stored 158 installed apps
I/flutter: Queued app_usage data for sync with priority 3  (×9 occurrences)
I/flutter: Apps: Processed 9 items
I/flutter: App usage periodic check complete: 9 new records
```

### 5.5 — Médias

```
I/flutter: Camera or storage permissions not granted  (première occurrence avant accord)
I/flutter: [MediaStore] initialized with per-category bootstrap checkpoints

I/flutter: [MediaStore] scanned 30 images items since 2026-03-12 20:20:28.045302 (bootstrap=true)
I/flutter: [MediaStore] images bootstrap completed: 30 items.
I/flutter: [MediaStore] scanned 2 videos items since 2026-03-12 20:20:28.290580 (bootstrap=true)
I/flutter: [MediaStore] videos bootstrap completed: 2 items.
I/flutter: [MediaStore] scanned 13 audio items since 2026-03-12 20:20:28.446841 (bootstrap=true)
I/flutter: [MediaStore] audio bootstrap completed: 13 items.
I/flutter: Advanced media collector started with config: high
```

> **⚠️ Observation** : 45 éléments médias collectés (30 images + 2 vidéos + 13 audios). La collecte des médias a démarré après l'accord des permissions `storage`/`media_*`.

---

## 6. Synchronisation en Masse (Bulk Sync)

### 6.1 — Premier envoi (batch 1 : SMS + apps)

```
I/flutter: [BulkSync] Candidates: sms=130, app_info=158, app_usage=18, location=6, media_metadata=45, calls=51
I/flutter: REQUEST[POST] => http://192.168.1.127:8000/api/v1/data/collect/bulk/
I/flutter: DATA => {device_id: 9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721, data_batches: [{data_type: messages, items: [...
  {message_type: SMS, direction: INCOMING, sender: MTN, body: "Bienvenue dans la communaute...", sent_at: 2026-04-24T14:55:12.005, ...},
  {message_type: SMS, direction: INCOMING, sender: WhatsApp, body: "#> Code WhatsApp : 883-282...", sent_at: 2026-04-24T19:20:14.319, ...},
  ...
I/flutter: RESPONSE[200] => http://192.168.1.127:8000/api/v1/data/collect/bulk/
I/flutter: DATA => {success: true, partial_success: false, device_id: 9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721, processed_batches: 2, successful_batches: 2, failed_batches: 0, results: [
  {data_type: messages, result: {success: true, processed_count: 100, error_count: 0, ...}},
  {data_type: app_info, result: {success: true, processed_count: 100, error_count: 0, ...}}
]}
```

### 6.2 — Deuxième envoi (batch 2 : SMS + apps + app_usage + location + media)

```
I/flutter: REQUEST[POST] => http://192.168.1.127:8000/api/v1/data/collect/bulk/
I/flutter: DATA => {device_id: 9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721, data_batches: [
  {data_type: messages, items: [
    {message_type: SMS, direction: INCOMING, sender: MTN, body: "Forfait 399U=2925U/30J...", sent_at: 2026-05-11T09:23:10.610, ...},
    {message_type: SMS, direction: INCOMING, sender: NewMoMoApp, body: "Gagne 8000F/j !...", sent_at: 2026-05-11T14:02:21.520, ...},
    ...
I/flutter: RESPONSE[200] => http://192.168.1.127:8000/api/v1/data/collect/bulk/
I/flutter: DATA => {success: true, partial_success: false, device_id: 9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721, processed_batches: 5, successful_batches: 5, failed_batches: 0, results: [
  {data_type: messages, result: {success: true, processed_count: 30, error_count: 0, ...}},
  {data_type: app_info, result: {success: true, processed_count: 58, error_count: 0, ...}},
  {data_type: app_usage, result: {success: true, processed_count: 18, error_count: 0, ...}},
  {data_type: location, result: {success: true, processed_count: 6, error_count: 0, ...}},
  {data_type: media_metadata, result: {success: true, processed_count: 45, error_count: 0, ...}}
]}
```

### 6.3 — Troisième envoi (appels)

```
I/flutter: REQUEST[POST] => http://192.168.1.127:8000/api/v1/data/collect/bulk/
I/flutter: DATA => {device_id: 9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721, data_batches: [{data_type: calls, items: [
  {call_type: OUTGOING, phone_number: 698841974, contact_name: Eric Vekout, start_time: 2026-04-24T13:56:06.376Z, end_time: null, duration: 0, ...},
  {call_type: OUTGOING, phone_number: 674561844, contact_name: Frigoriste, start_time: 2026-04-24T14:15:11.592Z, end_time: null, duration: 0, ...},
  ...
I/flutter: RESPONSE[200] => http://192.168.1.127:8000/api/v1/data/collect/bulk/
I/flutter: DATA => {success: true, partial_success: false, device_id: 9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721, processed_batches: 1, successful_batches: 1, failed_batches: 0, results: [
  {data_type: calls, result: {success: true, processed_count: 51, error_count: 0, ...}}
]}
```

### 6.4 — Résumé de synchronisation

```
I/flutter: Sync status updated: completed
I/flutter: Sync completed: 130 sms items
I/flutter: Sync status updated: completed
I/flutter: Sync completed: 158 app_info items
I/flutter: Sync status updated: completed
I/flutter: Sync completed: 18 app_usage items
I/flutter: Sync status updated: completed
I/flutter: Sync completed: 6 location items
I/flutter: Sync status updated: completed
I/flutter: Sync completed: 45 media_metadata items
I/flutter: Sync status updated: completed
I/flutter: Sync completed: 51 calls items
I/flutter: Marked 408 items as synced
I/flutter: Optimized bulk sync completed: 6 types, 408 items
I/flutter: No pending sync items found in database
```

---

## 7. Mise à Jour du Statut Appareil

```
I/flutter: REQUEST[PATCH] => http://192.168.1.127:8000/api/v1/devices/devices/9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721/
I/flutter: DATA => {battery_level: 100, is_charging: true, is_online: true, last_sync: 2026-06-10T20:19:07.299736, storage_available: 1073741824, network_type: wifi, location_enabled: true, permissions_status: {location: denied, camera: denied, microphone: denied, contacts: denied, sms: denied, call_log: denied, storage: denied, media_images: denied, media_video: denied, media_audio: denied}, app_version: 1.0.0-debug, os_version: 14, device_model: HONOR GFY-LX2, device_name: HONOR GFY-LX2}
I/flutter: RESPONSE[200] => http://192.168.1.127:8000/api/v1/devices/devices/9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721/
I/flutter: DATA => {id: 9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721, name: HONOR GFY-LX2, status: ONLINE, monitored_by: [{device_id: 29aeccd6-dd5f-48ba-93ef-373ae07ba4e6, device_name: Mon appareil (en cours de jumelage), permission_type: FULL_ACCESS}], display_mode: NORMAL, fcm_token_registered: false}
I/flutter: Device status updated successfully
```

> **⚠️ Note** : Première mise à jour avec toutes les permissions `denied` (avant accord). Le champ `fcm_token_registered: false` indique que le token FCM n'est pas enregistré.

---

## 8. Consentements

```
I/flutter: Processing consent data and signature...
I/flutter: Requesting consent for location - parentalControl
I/flutter: Consent recorded: location -> explicit
I/flutter: Consent for location: explicit
I/flutter: Requesting consent for communication - parentalControl
I/flutter: Consent recorded: communication -> ongoing
I/flutter: Consent for communication: ongoing
I/flutter: Requesting consent for appUsage - screenTimeManagement
I/flutter: Consent recorded: appUsage -> implicit
I/flutter: Consent for appUsage: implicit
I/flutter: Requesting consent for media - safetyMonitoring
I/flutter: Consent recorded: media -> implicit
I/flutter: Consent for media: implicit
I/flutter: Requesting consent for deviceInfo - parentalControl
I/flutter: Consent recorded: deviceInfo -> implicit
I/flutter: Consent for deviceInfo: implicit
I/flutter: Requesting consent for contacts - parentalControl
I/flutter: Consent recorded: contacts -> implicit
I/flutter: Consent for contacts: implicit
I/flutter: Consent processing completed successfully
```

---

## 9. Service d'Arrière-Plan & Background Isolate

```
I/flutter: Background service started
I/flutter: Enhanced battery status reported: 100%, charging: false, health: good
I/flutter: Switching to performance mode: maximum
I/flutter: Applied maximum performance mode
D/FlutterGeolocator: Geolocator foreground service connected
D/FlutterGeolocator: Initializing Geolocator services
D/FlutterGeolocator: Flutter engine connected. Connected engine count 2
I/flutter: Enhanced battery monitoring started
I/flutter: Enhanced battery status reported: 100%, charging: true, health: good

I/flutter: [DataCollector] Collection lease unavailable for background_isolate
I/flutter: [DataCollector] startCollectors() skipped: another isolate owns collection
I/flutter: Background isolate: another isolate owns collection; keeping service alive
I/flutter: Main isolate received: service_started
I/flutter: Enhanced battery status reported: 100%, charging: false, health: good
I/flutter: Enhanced battery monitoring started
I/flutter: Enhanced battery status reported: 100%, charging: true, health: good

I/flutter: Notification mode changed to VISIBLE
I/flutter: Auto start enabled
I/flutter: Initial configuration saved
I/flutter: Battery monitoring stopped
I/flutter: [DataCollector] startCollectors() skipped: collectors already running for main_isolate
```

> **⚠️ Observation** : Le background isolate ne peut pas démarrer les collecteurs car le main isolate détient le lease. Ce comportement est normal (single-owner), mais pourrait poser problème si le main isolate est mis en pause par Android.

---

## 10. Firebase / FCM — Erreurs

```
E/FirebaseMessaging: Topic sync or token retrieval failed on hard failure exceptions: java.util.concurrent.ExecutionException: java.io.IOException: FIS_AUTH_ERROR. Won't retry the operation.
E/FirebaseMessaging: Failed to get FIS auth token
E/FirebaseMessaging: java.util.concurrent.ExecutionException: com.google.firebase.installations.FirebaseInstallationsException: Firebase Installations Service is unavailable. Please try again later.
  (stack trace complète omise — même erreur à chaque tentative)

I/flutter: FCM token unavailable: unknown
I/flutter: DeviceService initialized successfully
```

> **⚠️ Impact** : Le token FCM n'est jamais obtenu, donc `fcm_token_registered: false`. Les notifications push ne fonctionneront pas. Cela n'affecte pas directement la collecte de données mais empêche les commandes push du backend.

---

## 11. WebSocket

```
I/flutter: WebSocket: Connecting with deviceId=9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721
I/flutter: WebSocket: Connected
I/flutter: WebSocket: Received message type: device_status
I/flutter: WebSocket: Received message type: device_status  (×plusieurs occurrences)
```

> **Observation** : La WebSocket est connectée et reçoit régulièrement des messages `device_status` du serveur.

---

## 12. Événements de Cycle de Vie (Android)

```
D/SessionLifecycleService: Service created on process 27294
D/SessionLifecycleService: Service bound to new client on process 27294
D/SessionLifecycleClient: Session update received.
D/SessionLifecycleClient: Notified CRASHLYTICS of new session 2c90a7f353004cfd99dd0afb7f85ed18
D/SessionLifecycleClient: Sending lifecycle 1 to service  (foreground)
D/SessionLifecycleService: Activity foregrounding at 161122506.
D/SessionLifecycleService: Cold start detected.
D/SessionLifecycleService: Generated new session.
D/SessionLifecycleService: Broadcasting new session
D/SessionFirelogPublisher: Data Collection is enabled for at least one Subscriber
D/EventGDTLogger: Session Event Type: SESSION_START
D/SessionFirelogPublisher: Successfully logged Session Start event.

D/SessionLifecycleClient: Sending lifecycle 2 to service  (background)
D/SessionLifecycleService: Activity backgrounding at 162117050
```

> **Observation** : Plusieurs allers-retours foreground/background observés, cohérents avec l'activation des permissions dans les réglages Android.

---

## 13. Permissions Android — Accès Settings

```
D/AccessibilityMonitoring: Window state changed: com.android.settings - com.android.settings.Settings$AccessibilitySettingsActivity
D/AccessibilityMonitoring: Window state changed: com.android.settings - com.android.settings.Settings$UsageAccessSettingsActivity
D/AccessibilityMonitoring: View clicked in com.android.settings: android.widget.LinearLayout
D/AccessibilityMonitoring: Window state changed: com.android.settings - com.hihonor.settingslib.SubSettings
D/AccessibilityMonitoring: View clicked in com.android.settings: android.widget.Button
```

> **Observation** : L'utilisateur a navigué dans les paramètres Android (Accessibilité, Accès à l'usage) pour accorder les permissions.

---

## 14. Résumé des Données Collectées & Synchronisées

| Type | Quantité collectée | Synchronisée (serveur) | Erreurs |
|------|-------------------|----------------------|---------|
| **SMS** | 130 (65 bootstrap + 65 new) | ✅ 130 items | 0 |
| **Appels** | 51 | ✅ 51 items | 0 |
| **Apps installées** | 158 | ✅ 158 items | 0 |
| **Usage apps** | 18 | ✅ 18 items | 0 |
| **Localisation** | 6 | ✅ 6 items | 0 |
| **Médias** | 45 (30 img + 2 vid + 13 audio) | ✅ 45 items | 0 |
| **Total** | **408** | ✅ **408 items** | **0** |

---

## 15. Problèmes Identifiés dans les Logs

### P1 — Permission Localisation NON accordée
```
permissions_status: {location: denied, ...}
```
Malgré cela, la collecte de localisation a fonctionné (6 points récupérés via Geolocator). **Impact** : risque d'arrêt de la collecte de localisation si Android restreint l'accès au GPS sans permission explicite.

### P2 — FCM / Firebase : token non obtenu
```
E/FirebaseMessaging: FIS_AUTH_ERROR
I/flutter: FCM token unavailable: unknown
I/flutter: fcm_token_registered: false
```
**Impact** : Pas de notifications push. Le backend ne peut pas envoyer de commandes au travers de FCM.

### P3 — Permissions initialement toutes refusées
Lors de la première initialisation, **toutes** les permissions étaient `denied`, empêchant toute collecte. Les collecteurs ont été initialisés en mode dégradé (`bootstrapPending=true`) et n'ont démarré la collecte qu'après l'accord manuel des permissions dans les réglages Android.

### P4 — Background isolate ne peut pas collecter
```
I/flutter: [DataCollector] Collection lease unavailable for background_isolate
I/flutter: [DataCollector] startCollectors() skipped: another isolate owns collection
```
Le background isolate cède la place au main isolate pour la collecte. Si le main isolate est mis en pause par Android (écoénergétique), la collecte s'arrête.