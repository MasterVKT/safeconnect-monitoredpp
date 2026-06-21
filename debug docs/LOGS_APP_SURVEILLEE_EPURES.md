# Logs épurés de l'application surveillée (Monitored App)

**Date de génération** : 07/06/2026
**Appareil** : GFY LX2 (Honor) - Android 14 (API 34)
**Mode** : Debug
**API** : http://192.168.1.127:8000/api/v1
**Process ID** : 21089
**Code de jumelage** : 477943
**Device ID** : 9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721
**User** : ericvekout@gmail.com (Eric Vekout)

> **Note** : Ces logs ont été filtrés pour l'analyse des problèmes d'accès et d'affichage des données de l'appareil surveillé depuis l'application surveillante — spécifiquement les données dont l'accès ou l'affichage pose problème : **Medias, Liste des appels, Apps, Localisation**. Les doublons sur lignes uniques ou en blocs (ViewTreeObserver, ApkAssets, InputMethodManager, HiTouch, SurfaceControl, BufferQueue, RtgSched, IME, AccessibilityMonitoring, ActivityLifecycle, Choreographer `Skipped N frames`, `Queued ... data for sync`, `Sync status updated: idle`, etc.) ont été supprimés ou condensés. Aucune altération des informations conservées.

---

## 1. Démarrage et configuration initiale

### Lancement et installation
```
(.venv) PS H:\Projects\XP SafeConnect\flutter_apps\monitored_app> flutter run --dart-define=API_BASE_URL=http://192.168.1.127:8000 | Select-String -NotMatch "EGL_emulation"

Connected devices:
GFY LX2 (mobile)             • A2SJCP4A19414110 • android-arm64  • Android 14 (API 34)
sdk gphone64 x86 64 (mobile) • emulator-5554    • android-x64    • Android 12 (API 31) (emulator)
Windows (desktop)            • windows          • windows-x64    • Microsoft Windows [version 10.0.19045.7291]
Chrome (web)                 • chrome           • web-javascript • Google Chrome 147.0.7727.138
Edge (web)                   • edge             • web-javascript • Microsoft Edge 148.0.3967.83
Please choose one (or "q" to quit): 1
Launching lib\main.dart on GFY LX2 in debug mode...
Running Gradle task 'assembleDebug'...                           118,3s
✓ Built build\app\outputs\flutter-apk\app-debug.apk
Installing build\app\outputs\flutter-apk\app-debug.apk...          15,2s
```

### Contexte d'exécution natif
```
I/flutter (21089):
[INFO:flutter/shell/platform/android/android_context_vk_impeller.cc(65)] Known bad Vulkan driver encountered, falling back to OpenGLES.
I/flutter (21089):
[IMPORTANT:flutter/shell/platform/android/android_context_gl_impeller.cc(94)] Using the Impeller rendering backend (OpenGLES).
D/FlutterGeolocator(21089): Attaching Geolocator to activity
D/FlutterGeolocator(21089): Creating service.
D/FlutterGeolocator(21089): Binding to location service.
D/FlutterGeolocator(21089): Geolocator foreground service connected
D/FlutterGeolocator(21089): Initializing Geolocator services
D/FlutterGeolocator(21089): Flutter engine connected. Connected engine count 1
```

### Init de la session et Crashlytics
```
D/SessionLifecycleService(21089): Service created on process 21089
D/SessionLifecycleService(21089): Service bound to new client on process 21089
D/SessionLifecycleService(21089): Cold start detected.
D/SessionLifecycleService(21089): Generated new session.
D/SessionLifecycleService(21089): Broadcasting new session
D/SessionLifecycleClient(21089): Session update received.
D/SessionLifecycleClient(21089): Notified CRASHLYTICS of new session b3e2709573324586a9f0647702920ea4
D/EventGDTLogger(21089): Session Event Type: SESSION_START
D/SessionFirelogPublisher(21089): Successfully logged Session Start event.
```

> *Plusieurs dizaines de `W/ViewTreeObserver: onPreDraw return false io.flutter.embedding.android.FlutterActivityAndFragmentDelegate$2@2ee3638` ont été supprimées (doublons systématiques).*

---

## 2. Initialisation de l'AppConfig et des services (main isolate)

### AppConfig et base de données
```
I/flutter (21089): AppConfig initialized: env=dev, api=http://192.168.1.127:8000/api/v1, displayMode=NORMAL
I/flutter (21089): Database initialized with encryption
I/flutter (21089): Skipping SecurityService.initialize() in debug mode
I/flutter (21089): Skipping EmergencyService.initialize() in debug mode
I/flutter (21089): Skipping StealthService.initialize() in debug mode
I/flutter (21089): Skipping AntiTamperService.initialize() in debug mode
I/flutter (21089): Skipping RASPService.initialize() in debug mode
I/flutter (21089): Skipping SecurityMonitoringService.initialize() in debug mode
I/flutter (21089): Camera or storage permissions not granted
```

### Services système
```
I/flutter (21089): Media scheduler started
I/flutter (21089): Bandwidth optimization started
I/flutter (21089): Advanced Media Service initialized successfully
I/flutter (21089): BatteryMonitorService initialized
I/flutter (21089): Initializing Performance Optimizer...
I/flutter (21089): Loaded performance configuration: mode=balanced, strategy=moderate
I/flutter (21089): Setup 5 optimization rules
I/flutter (21089): Performance Optimizer initialized
I/flutter (21089): SyncStatusMonitor initialized
I/flutter (21089): Sync status updated: idle
I/flutter (21089): DeviceService initialization skipped: no authenticated session yet
I/flutter (21089): PerformanceMonitor initialized
I/flutter (21089): ConsentManager initialized with 0 active consents
W/PerformancePlugin(21089): CPU global metrics unavailable on this device; using process-level fallback (FileNotFoundException).
```

> *~18 lignes `I/flutter (21089): Sync status updated: idle` (doublons) ont été supprimées — une seule conservée à titre d'état initial.*

### P2P / WebRTC
```
I/flutter (21089): P2P Communication Service initialized
I/flutter (21089): P2P Signaling Service initialized
I/flutter (21089): P2P Command Handler initialized
I/flutter (21089): Loaded 4 ICE servers
I/org.webrtc.Logging(21089): NativeLibrary: Loading native library: jingle_peerconnection_so
I/flutter (21089): WebRTC initialized for platform: android
I/flutter (21089): WebRTC metrics collection started
I/flutter (21089): WebRTC heartbeat started
I/flutter (21089): WebSocket: Handler added for message type: webrtc_signaling
I/flutter (21089): WebSocket: Handler added for message type: peer_connection_request
I/flutter (21089): WebSocket handlers setup for WebRTC signaling
I/flutter (21089): Production WebRTC Service initialized successfully
I/flutter (21089): P2P Manager state changed to: P2PManagerState.initializing
I/flutter (21089): P2P Manager state changed to: P2PManagerState.ready
I/flutter (21089): P2P Manager initialized successfully
I/flutter (21089): Initializing P2P File Transfer Service...
I/flutter (21089): Temp directory setup: /data/user/0/com.xpsafeconnect.monitored_app/code_cache/monitored_app_transfers
I/flutter (21089): File transfer message handlers setup
I/flutter (21089): Loaded 0 pending file transfer sessions
I/flutter (21089): P2P File Transfer Service initialized
I/flutter (21089): TestValidationService initialized successfully
```

### Crashlytics
```
I/TRuntime.CctTransportBackend(21089): Making request to: https://firebaselogging-pa.googleapis.com/v1/firelog/legacy/batchlog
I/TRuntime.CctTransportBackend(21089): Status Code: 200
```

---

## 3. Jumelage de l'appareil

### Saisie du code de jumelage
```
I/flutter (21089): Starting device pairing with code: 477943
I/flutter (21089): [PAIRING] Starting device pairing process...
I/flutter (21089): [PAIRING] Calling validate-pairing-code endpoint...
```

### POST /api/v1/devices/validate-pairing-code/
```
I/flutter (21089): REQUEST[POST] => http://192.168.1.127:8000/api/v1/devices/validate-pairing-code/
I/flutter (21089): DATA => {pairing_code: 477943, pairingCode: 477943, device_identifier: HONORGFY-L32, device_info: {platform: ANDROID, device_name: HONOR GFY-LX2, model: GFY-LX2, device_model: HONOR GFY-LX2, manufacturer: HONOR, device_id: HONORGFY-L32, os_version: 14, sdk_version: 34, app_version: 1.0.0-debug, app_build_number: 1}, deviceInfo: {platform: ANDROID, device_name: HONOR GFY-LX2, model: GFY-LX2, device_model: HONOR GFY-LX2, manufacturer: HONOR, device_id: HONORGFY-L32, os_version: 14, sdk_version: 34, app_version: 1.0.0-debug, app_build_number: 1}}
I/flutter (21089): RESPONSE[200] => http://192.168.1.127:8000/api/v1/devices/validate-pairing-code/
I/flutter (21089): DATA => {success: true, message: Jumelage réussi, device_id: 9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721, device: {id: 9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721, name: Mon appareil (en cours de jumelage), device_name: Mon appareil (en cours de jumelage), device_identifier: HONORGFY-L32, platform: ANDROID, model: A configurer, device_model: A configurer, os_version: 0, is_monitored: true, is_monitoring: false, last_seen: null, last_sync: null, is_online: false, battery_level: null, is_charging: false, created_at: 2026-06-07T02:41:52.318902Z, updated_at: 2026-06-07T02:41:52.318902Z, user: {id: 1c1261a0-819e-49c1-a236-48d7c03aa942, email: ericvekout@gmail.com, full_name: Eric Vekout}, status: UNKNOWN, monitored_by: [{device_id: 29aeccd6-dd5f-48ba-93ef-373ae07ba4e6, device_name: Mon appareil (en cours de jumelage), user: {id: 1c1261a0-819e-49c1-a236-48d7c03aa942, email: ericvekout@gmail.com, full_name: Eric Vekout}, permission_type: FULL_ACCESS, granted_at: 2026-06-07T02:41:52.363604+00:00}], monitoring: [], display_mode: NORMAL}
```

> **🔑 Observation** : Le backend retourne `display_mode: NORMAL` dans la réponse de jumelage. La valeur `model: "A configurer"`, `device_model: "A configurer"`, `os_version: 0` et `status: UNKNOWN` indique un device nouvellement créé, non encore configuré. Le `permission_type: FULL_ACCESS` est accordé au `monitored_by` (le device surveillant).

### Finalisation du pairing et démarrage du service
```
I/flutter (21089): [PAIRING] Received response: 200
I/flutter (21089): [PAIRING] Parsing auth response...
I/flutter (21089): [PAIRING] Auth response parsed successfully
I/flutter (21089): [PAIRING] Storing auth data...
I/flutter (21089): [PAIRING] Storing paired device ID: 9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721
I/flutter (21089): [PAIRING] Connecting WebSocket...
I/flutter (21089): WebSocket: Connecting with deviceId=9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721
I/flutter (21089): WebSocket: Connected
I/flutter (21089): [PAIRING] Starting DeviceService in background...
I/flutter (21089): [PAIRING] Starting token refresh...
I/flutter (21089): [PAIRING] Logging security event...
I/flutter (21089): [PAIRING] Skipping security event log - not initialized
I/flutter (21089): [PAIRING] Pairing completed successfully!
I/flutter (21089): [PAIRING] Triggering initial full data sync with new auth tokens...
I/flutter (21089): [DataCollector] Releasing prior lease due to permission change
I/flutter (21089): Device pairing successful
I/flutter (21089): [DataCollector] Restarting collectors after permission change
I/flutter (21089): No pending sync items found in database
I/flutter (21089): No server configuration available, using defaults
```

---

## 4. Initialisation des collecteurs (PRE-permissions)

### SMS / Calls / Location / Apps / Media
```
I/flutter (21089): Initializing SMS collector
I/flutter (21089): SMS: Required permissions not granted
I/flutter (21089): [SMS] initialized with bootstrapDone=false, lastCheckTime=null
I/flutter (21089): SMS collector initialized successfully
I/flutter (21089): Initializing Calls collector
I/flutter (21089): Calls: Required permissions not granted
I/flutter (21089): [Calls] initialized with bootstrapDone=false, lastCheckTime=null
I/flutter (21089): Calls collector initialized successfully
I/flutter (21089): Initializing Location collector
I/flutter (21089): Location: Required permissions not granted
I/flutter (21089): Location collector initialized successfully
I/flutter (21089): Initializing Apps collector
I/flutter (21089): Apps: Required permissions not granted
I/flutter (21089): Apps collector specific initialization completed
I/flutter (21089): Apps collector initialized successfully
I/flutter (21089): Camera or storage permissions not granted
I/flutter (21089): [MediaStore] initialized with bootstrapDone=false, lastScanTime=null
```

### GET /api/v1/data/collection-config/ (1ère exécution — pas d'auth au démarrage)
```
I/flutter (21089): REQUEST[GET] => http://192.168.1.127:8000/api/v1/data/collection-config/?device_id=9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721
I/flutter (21089): DATA => null
I/flutter (21089): RESPONSE[200] => http://192.168.1.127:8000/api/v1/data/collection-config/?device_id=9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721
I/flutter (21089): DATA => {location: {enabled: true, interval_seconds: 900, accuracy: BALANCED}, messages: {enabled: true, types: [SMS, MMS, WHATSAPP, TELEGRAM, MESSENGER], include_content: true}, calls: {enabled: true, record_calls: false}, app_usage: {enabled: true, interval_minutes: 30}, media: {enabled: true, scan_interval_hours: 24, include_thumbnails: false}}
I/flutter (21089): Collection configuration loaded: (location, messages, calls, app_usage, media)
```

### Blocages par permissions manquantes
```
I/flutter (21089): SMS: Cannot start collection - permissions not granted
I/flutter (21089): Calls: Cannot start collection - permissions not granted
I/flutter (21089): Location: Cannot start collection - permissions not granted
I/flutter (21089): Apps: Cannot start collection - permissions not granted
I/flutter (21089): [MEDIA] Cannot start media collection: permissions not granted
I/flutter (21089): [MediaStore] Cannot start scan: media read permissions missing
I/flutter (21089): [DataCollector] Sync: isSyncing=false, queueEmpty=true
```

---

## 5. Premier PATCH device status (toutes permissions = denied)

### PATCH /api/v1/devices/devices/{id}/ — body initial
```
I/flutter (21089): REQUEST[PATCH] => http://192.168.1.127:8000/api/v1/devices/devices/9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721/
I/flutter (21089): DATA => {battery_level: 97, is_charging: true, is_online: true, last_sync: 2026-06-07T03:42:30.103699, storage_available: 1073741824, network_type: wifi, location_enabled: false, permissions_status: {location: denied, camera: denied, microphone: denied, contacts: denied, sms: denied, call_log: denied, storage: denied, media_images: denied, media_video: denied, media_audio: denied}, app_version: 1.0.0-debug, os_version: 14, device_model: HONOR GFY-LX2, device_name: HONOR GFY-LX2}
I/flutter (21089): RESPONSE[200] => http://192.168.1.127:8000/api/v1/devices/devices/9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721/
I/flutter (21089): Device status updated successfully
```

### PATCH /api/v1/devices/devices/{id}/ — enregistrement FCM token
```
I/flutter (21089): REQUEST[PATCH] => http://192.168.1.127:8000/api/v1/devices/devices/9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721/
I/flutter (21089): DATA => {fcm_token: c360WU-8R-W16pgMMD_qpZ:APA91bGCgJbM1DNh6cSDTNSXtmjfHJ11dJhDruxCafBbAalAsv6ThfZ9xwoNnsmFc6WKP_d4gGVtbYxqjOlzAqDNuy53PtNATxQkO0CrWdy89KQ6k6T32NI}
I/flutter (21089): RESPONSE[200] => http://192.168.1.127:8000/api/v1/devices/devices/9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721/
I/flutter (21089): DATA => {id: 9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721, name: HONOR GFY-LX2, device_name: HONOR GFY-LX2, device_identifier: HONORGFY-L32, platform: ANDROID, model: HONOR GFY-LX2, device_model: HONOR GFY-LX2, os_version: 14, is_monitored: true, is_monitoring: false, last_seen: 2026-06-07T03:42:30.103699Z, last_sync: 2026-06-07T03:42:30.103699Z, is_online: true, battery_level: 97, is_charging: true, created_at: 2026-06-07T02:41:52.318902Z, updated_at: 2026-06-07T02:41:56.855406Z, user: {id: 1c1261a0-819e-49c1-a236-48d7c03aa942, email: ericvekout@gmail.com, full_name: Eric Vekout}, status: ONLINE, monitored_by: [{device_id: 29aeccd6-dd5f-48ba-93ef-373ae07ba4e6, device_name: Mon appareil (en cours de jumelage), user: {id: 1c1261a0-819e-49c1-a236-48d7c03aa942, email: ericvekout@gmail.com, full_name: Eric Vekout}, permission_type: FULL_ACCESS, granted_at: 2026-06-07T02:41:52.363604+00:00}], monitoring: [], display_mode: NORMAL, fcm_token_registered: false}
I/flutter (21089): FCM token registered successfully
I/flutter (21089): DeviceService initialized successfully
I/flutter (21089): [PAIRING] DeviceService background initialization completed
```

> **🔑 Observation** : Le `display_mode` est persisté côté backend à `NORMAL`. Si l'app surveillante envoie ensuite une commande pour passer en `DISCRETE` ou `INVISIBLE`, ce PATCH ne rejoue pas le `display_mode` — aucun log d'événement WebSocket entrant concernant un changement de `display_mode` n'apparaît dans cette exécution.

---

## 6. Traitement des consentements
```
I/flutter (21089): Processing consent data and signature...
I/flutter (21089): Requesting consent for location - parentalControl
I/flutter (21089): Consent recorded: location -> explicit
I/flutter (21089): Consent for location: explicit
I/flutter (21089): Requesting consent for communication - parentalControl
I/flutter (21089): Consent recorded: communication -> ongoing
I/flutter (21089): Consent for communication: ongoing
I/flutter (21089): Requesting consent for appUsage - screenTimeManagement
I/flutter (21089): Consent recorded: appUsage -> implicit
I/flutter (21089): Consent for appUsage: implicit
I/flutter (21089): Requesting consent for media - safetyMonitoring
I/flutter (21089): Consent recorded: media -> implicit
I/flutter (21089): Consent for media: implicit
I/flutter (21089): Requesting consent for deviceInfo - parentalControl
I/flutter (21089): Consent recorded: deviceInfo -> implicit
I/flutter (21089): Consent for deviceInfo: implicit
I/flutter (21089): Requesting consent for contacts - parentalControl
I/flutter (21089): Consent recorded: contacts -> implicit
I/flutter (21089): Consent for contacts: implicit
I/flutter (21089): Consent processing completed successfully
```

---

## 7. Phase d'octroi des permissions (admin, usage access, location)
```
D/AntiUninstallAdmin(21089): Device admin enabled
D/AntiUninstallAdmin(21089): Remote notification queued: admin_activated
D/CompatibilityChangeReporter(21089): Compat change id reported: 147798919; UID 10142; state: ENABLED
```

> *Pendant cette phase, l'utilisateur navigue vers les écrans système. Le service d'accessibilité enregistre l'enchaînement des fenêtres via `D/AccessibilityMonitoring` (condensé ici) : `com.android.settings.Settings$AccessibilitySettingsActivity` → `Settings$UsageAccessSettingsActivity` → `com.hihonor.settingslib.SubSettings` → `com.android.settings.Settings$DeviceAdminAdd` → `com.google.android.googlequicksearchbox` → `com.hihonor.android.launcher.drawer.DrawerLauncher` → `com.google.android.gms.LocationSettingsCheckerActivity` → fenêtre Settings (Dialog). Puis notification système `Protection activée` émise par `com.xpsafeconnect.monitored_app`.*
>
> *Aucune erreur d'accessibilité ni de permission n'est loguée — toutes les boites de dialogue sont validées par l'utilisateur.*

---

## 8. Reprise après octroi des permissions — collecte effective

### Restart des collecteurs (sur permission change)
```
I/flutter (21089): [DataCollector] Releasing prior lease due to permission change
I/flutter (21089): [DataCollector] Restarting collectors after permission change
```

### 📱 SMS — bootstrap 60 messages
```
I/flutter (21089): SMS specific collection started
I/flutter (21089): SMS collector started with interval: 900 seconds
D/SmsCollectorPlugin(21089): getNewSms query returned 60 rows since 1773024247026
I/flutter (21089): [SMS] getNewSms returned 60 entries since 2026-03-09 03:44:07.026215 (bootstrap=true)
I/flutter (21089): [SMS] Collection skipped: another collection is running
I/flutter (21089): [SMS] Bootstrap completed: 60 historical SMS captured.
I/flutter (21089): SMS: Processed 60 items
I/flutter (21089): SMS periodic check complete: 60 new messages
```

> *60 lignes `I/flutter (21089): Queued sms data for sync with priority 1` (collecte initiale) + 60 lignes `Queued sms data for sync with priority 2` (re-queue) ont été **supprimées** — les compteurs (60 capturés, 60 traités, 60 nouveaux) sont conservés ci-dessus.*

### 📞 Calls — bootstrap 48 appels
```
I/flutter (21089): Calls specific collection started
I/flutter (21089): Calls collector started with interval: 900 seconds
I/flutter (21089): [Calls] Collection skipped: another collection is running
I/flutter (21089): [Calls] getNewCalls returned 48 entries since 2026-03-09 03:44:08.193806 (bootstrap=true)
I/flutter (21089): [Calls] Collection skipped: another collection is running
I/flutter (21089): [Calls] Bootstrap completed: 48 historical calls captured.
I/flutter (21089): Calls: Processed 48 items
I/flutter (21089): Calls periodic check complete: 48 new calls
```

### 📍 Location — collecte désactivée
```
I/flutter (21089): Location specific collection started with interval: 900 seconds
I/flutter (21089): Location collector started with interval: 900 seconds
E/FlutterGeolocator(21089): Geolocator position updates started
I/flutter (21089): [LOCATION] System location services disabled. Collection paused until re-enabled.
E/FlutterGeolocator(21089): Geolocator position updates stopped
E/FlutterGeolocator(21089): There is still another flutter engine connected, not stopping location service
```

> **🔴 Problème potentiel** : `[LOCATION] System location services disabled` — la collecte de localisation est mise en pause tant que la géolocalisation système n'est pas activée. La config backend `location: { enabled: true, interval_seconds: 900, accuracy: BALANCED }` est en discordance avec l'état device. Si l'app surveillante affiche la position, elle ne recevra rien tant que l'utilisateur n'active pas manuellement la géolocalisation système (l'écran `LocationSettingsCheckerActivity` a été ouvert mais la validation effective n'est pas confirmée dans les logs).

### 📦 Apps — 158 apps installées + 12 enregistrements d'usage
```
I/flutter (21089): Apps specific collection started
I/flutter (21089): Apps collector started with interval: 900 seconds
I/ApplicationPackageManager(21089): checkGetInstalledAppsPermissionStatus,packageName:com.xpsafeconnect.monitored_app,ret:-2
I/flutter (21089): Collected and stored 158 installed apps
I/flutter (21089): Apps: Processed 12 items
I/flutter (21089): App usage periodic check complete: 12 new records
```

> *Notes* :
> * - `ret:-2` correspond à `PackageManager.PERMISSION_DENIED` ; l'app s'appuie vraisemblablement sur `QUERY_ALL_PACKAGES` (Android 11+) ou un fallback agressif pour arriver à 158 apps malgré ce code d'erreur.
> * - Différence de volume : `app_info` (158 items) vs `app_usage` (12 items) — le frontend appelle deux endpoints distincts.
> * - **~158 lignes** `Queued app_info data for sync with priority 3` et **~24 lignes** `Queued app_usage data for sync with priority 2/3` ont été **supprimées** — les totaux sont conservés ci-dessus.

### 🖼️ Media — 45 items scannés
```
I/flutter (21089): Advanced media collector started with config: high
I/flutter (21089): [MediaStore] scanned 45 items since 2026-03-09 03:44:14.010 (bootstrap=true)
I/flutter (21089): [MediaStore] Bootstrap completed: 45 items.
```

> *45 items de `media_metadata` uploadés. Si l'app surveillante n'affiche pas les médias, vérifier :*
> * - les permissions `media_images`, `media_video`, `media_audio` (passent à `granted` dans le 2nd PATCH — voir §10)
> * - le format de réponse de l'endpoint `/api/v1/data/media/` côté Django (non visible dans ces logs monitored_app)

---

## 9. Bulk sync vers le backend

### POST /api/v1/data/collect/bulk/ — batch #1 (sms + app_info)
```
I/flutter (21089): Sync status updated: syncing
I/flutter (21089): REQUEST[POST] => http://192.168.1.127:8000/api/v1/data/collect/bulk/
I/flutter (21089): DATA => {device_id: 9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721, data_batches: [{data_type: messages, items: [{message_type: SMS, direction: INCOMING, sender: MTN, sender_name: null, body: Bienvenue dans la communaute la plus incroyable, MTN YaMo! Tu es proche de gagner une bourse de 50 000F. Inscris toi VITE sur yamo.mtn.cm., sent_at: 2026-04-24T14:55:12.005, conversation_id: 1, has_attachment: false}, {message_type: SMS, direction: INCOMING, sender: WhatsApp, sender_name: null, body: <#> Code WhatsApp : 883-282\nNe partagez pas ce code\n4sgLq1p5sV6, sent_at: 2026-04-24T19:20:14.319, conversation_id: 2, has_attachment: false}, {message_type: SMS, direction: INCOMING, sender: MTN, sender_name: null, body: Oups ! Nous avons des difficultes a vous connecter sur Internet. Consultez votre solde Internet pour confirmer que vous avez encore du volume : *123*99#, sent_at: 2026-04-25T00:13:47.690, conversation_id: 1, has_attachment: false}, {message_type: SMS, direction: INCOMING, sender: Reviens, sender_name: null, body: PR...}]}]}
I/flutter (21089): RESPONSE[200] => http://192.168.1.127:8000/api/v1/data/collect/bulk/
I/flutter (21089): DATA => {success: true, partial_success: false, device_id: 9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721, processed_batches: 2, successful_batches: 2, failed_batches: 0, results: [{data_type: messages, result: {success: true, processed_count: 100, error_count: 0, batch_id: 4f3fc207-4b44-4e19-8560-87f1a587bda8, device_id: 9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721, data_type: messages, item_errors: []}}, {data_type: app_info, result: {success: true, processed_count: 100, error_count: 0, batch_id: f7a5eb8f-ef97-43cd-86f0-ec76d8373f06, device_id: 9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721, data_type: app_info, item_errors: []}}]}
```

### POST /api/v1/data/collect/bulk/ — batch #2 (sms restants + app_info restants + app_usage + media)
```
I/flutter (21089): REQUEST[POST] => http://192.168.1.127:8000/api/v1/data/collect/bulk/
I/flutter (21089): DATA => {device_id: 9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721, data_batches: [{data_type: messages, items: [{message_type: SMS, direction: INCOMING, sender: Imbattable, body: Stop au Compromis ! La solution est dans tes mains. Decouvres des offres voix et data exceptionnels  au *222*0#, sent_at: 2026-05-16T08:04:04.607, thread_id: 10, has_attachment: false, collected_at: 2026-06-07T03:44:07.907732}, {message_type: SMS, direction: INCOMING, sender: WeekendDose, body: Encore un weekend qui va donner. Tu veux surfer? Appeler tous reseaux? Tape *237# et enjoy ton weekend avec 200 F seulement , sent_at: 2026-05-16T14:42:57.682, thread_id: 4, has_attachment: false, collected_at: 2026-06-07T03:44:07.907732}, {message_type: SMS, direction: INCOMING, sender: WeekendDose, body: Imagine le gout de parler sans limite. 200U=2050U tous reseaux + 2000U MTN /24H + 200 SMS. *237# pour decouvrir le reste, sent_at: 202I/flutter (21089): RESPONSE[200] => http://192.168.1.127:8000/api/v1/data/collect/bulk/
I/flutter (21089): DATA => {success: true, partial_success: false, device_id: 9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721, processed_batches: 4, successful_batches: 4, failed_batches: 0, results: [{data_type: messages, result: {success: true, processed_count: 20, error_count: 0, batch_id: 21ef8732-3055-4463-90c4-ed62d66f1f44, device_id: 9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721, data_type: messages, item_errors: []}}, {data_type: app_info, result: {success: true, processed_count: 58, error_count: 0, batch_id: 4fa9754f-989c-4eda-a712-63916bddc09f, device_id: 9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721, data_type: app_info, item_errors: []}}, {data_type: app_usage, result: {success: true, processed_count: 24, error_count: 0, batch_id: d98db6c0-0021-45d0-add6-98ae5294b73f, device_id: 9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721, data_type: app_usage, item_errors: []}}, {data_type: media, result: {success: true, processed_count: 45, error_count: 0, batch_id: 127258bc-1e8d-4d0b-bdb3-d2f2ae214698, device_id: 9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721, data_type: media, item_errors: []}}]}
```

### Résumé de la sync
```
I/flutter (21089): Sync status updated: completed
I/flutter (21089): Sync completed: 120 sms items
I/flutter (21089): Sync status updated: completed
I/flutter (21089): Sync completed: 158 app_info items
I/flutter (21089): Sync status updated: completed
I/flutter (21089): Sync completed: 24 app_usage items
I/flutter (21089): Sync status updated: completed
I/flutter (21089): Sync completed: 45 media_metadata items
I/flutter (21089): Marked 347 items as synced
I/flutter (21089): Optimized bulk sync completed: 4 types, 347 items
I/flutter (21089): Sync status updated: completed
```

---

## 10. Reprise après sync — second PATCH device status (permissions = granted)

### PATCH /api/v1/devices/devices/{id}/ — après octroi des permissions
```
I/flutter (21089): REQUEST[PATCH] => http://192.168.1.127:8000/api/v1/devices/devices/9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721/
I/flutter (21089): DATA => {battery_level: 97, is_charging: true, is_online: true, last_sync: 2026-06-07T03:44:33.381266, storage_available: 1073741824, network_type: wifi, location_enabled: true, permissions_status: {location: denied, camera: granted, microphone: granted, contacts: granted, sms: granted, call_log: granted, storage: granted, media_images: granted, media_video: granted, media_audio: granted}, app_version: 1.0.0-debug, os_version: 14, device_model: HONOR GFY-LX2, device_name: HONOR GFY-LX2}
I/flutter (21089): RESPONSE[200] => http://192.168.1.127:8000/api/v1/devices/devices/9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721/
I/flutter (21089): DATA => {id: 9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721, name: HONOR GFY-LX2, device_name: HONOR GFY-LX2, device_identifier: HONORGFY-L32, platform: ANDROID, model: HONOR GFY-LX2, device_model: HONOR GFY-LX2, os_version: 14, is_monitored: true, is_monitoring: false, last_seen: 2026-06-07T03:44:33.381266Z, last_sync: 2026-06-07T03:44:33.381266Z, is_online: true, battery_level: 97, is_charging: true, created_at: 2026-06-07T02:41:52.318902Z, updated_at: 2026-06-07T02:43:59.871944Z, user: {id: 1c1261a0-819e-49c1-a236-48d7c03aa942, email: ericvekout@gmail.com, full_name: Eric Vekout}, status: ONLINE, monitored_by: [{device_id: 29aeccd6-dd5f-48ba-93ef-373ae07ba4e6, device_name: Mon appareil (en cours de jumelage), user: {id: 1c1261a0-819e-49c1-a236-48d7c03aa942, email: ericvekout@gmail.com, full_name: Eric Vekout}, permission_type: FULL_ACCESS, granted_at: 2026-06-07T02:41:52.363604+00:00}], monitoring: [], display_mode: NORMAL, fcm_token_registered: false}
I/flutter (21089): Device status updated successfully
I/flutter (21089): FCM token registered successfully
I/flutter (21089): DeviceService initialized successfully
```

> **🔑 Observation** : entre le 1er PATCH (`toutes permissions = denied`) et ce 2nd PATCH :
> * - `camera`, `microphone`, `contacts`, `sms`, `call_log`, `storage`, `media_images`, `media_video`, `media_audio` sont passées à `granted`.
> * - `location` reste à `denied` (l'utilisateur a ouvert `LocationSettingsCheckerActivity` mais ne l'a apparemment pas validée, ou le service de localisation n'est pas activé).
> * - `location_enabled` passe de `false` à `true` au niveau du payload (probablement un état "feature flag" ≠ "permission runtime").
> * - `display_mode` reste à `NORMAL` — aucune modification de mode n'a eu lieu via WebSocket pendant cette session.

---

## 11. Cycle de vie background isolate et événements WebSocket

### Redémarrage background isolate
```
I/flutter (21089): Battery monitoring stopped
I/flutter (21089): [DataCollector] Collection lease unavailable for background_isolate
I/flutter (21089): [DataCollector] startCollectors() skipped: another isolate owns collection
I/flutter (21089): Background isolate: another isolate owns collection; keeping service alive
I/flutter (21089): Main isolate received: service_started
I/flutter (21089): Background service started
I/flutter (21089): Enhanced battery status reported: 97%, charging: false, health: good
I/flutter (21089): Switching to performance mode: maximum
I/flutter (21089): Applied maximum performance mode
I/flutter (21089): Enhanced battery monitoring started
I/flutter (21089): Enhanced battery status reported: 97%, charging: true, health: good
I/flutter (21089): Sync status updated: completed
I/flutter (21089): Advanced media configuration updated: high quality, light compression
I/flutter (21089): Media collection optimized for 5000kbps bandwidth
```

> **🔑 Observation importante — problème `dual isolate`** : le background isolate tente de démarrer les collecteurs mais s'arrête immédiatement car le main isolate les possède déjà (`Collection lease unavailable for background_isolate`, `startCollectors() skipped: another isolate owns collection`). C'est cohérent avec le fichier [`debug docs/MONITORED_APP_ISSUE_DUAL_ISOLATE_COLLECTOR_RACE_20260512.md`](./MONITORED_APP_ISSUE_DUAL_ISOLATE_COLLECTOR_RACE_20260512.md). Aucune erreur HTTP 5xx n'est levée — la coordination fonctionne mais le `Display mode changed` n'est jamais loggué après le démarrage.

### Événements WebSocket entrants (uniquement `device_status`)
```
I/flutter (21089): WebSocket: Received message type: device_status   ← x4 pendant la session
I/flutter (21089): Display mode changed to NORMAL
I/flutter (21089): Notification mode changed to VISIBLE
I/flutter (21089): Auto start enabled
I/flutter (21089): Initial configuration saved
I/flutter (21089): Battery monitoring stopped
I/flutter (21089): [DataCollector] startCollectors() skipped: collectors already running for main_isolate
```

> *Aucun message WebSocket entrant de type `request_data_sync`, `change_display_mode`, `lock_device`, `wipe_data`, `request_location_now` n'apparaît pendant cette exécution — l'app surveillante n'a envoyé aucune commande vers ce device pendant l'enregistrement des logs. La seule commande `display_mode = NORMAL` est émise **par le device** lui-même (probablement en réponse au `ConfigCommand initial` reçu au démarrage).*

### Configuration locale persistée
```
I/flutter (21089): AppConfig initialized: env=dev, api=http://192.168.1.127:8000/api/v1, displayMode=NORMAL   ← (2ème init, en background isolate)
I/flutter (21089): Database initialized with encryption
I/flutter (21089): BatteryMonitorService initialized
I/flutter (21089): SyncStatusMonitor initialized
I/flutter (21089): Collection configuration loaded: (location, messages, calls, app_usage, media)
```

### `Application finished`
```
Application finished.
```

---

## 12. Synthèse pour l'analyse des problèmes d'accès/affichage (app surveillante)

### Données effectivement uploadées vers le backend (POST `/api/v1/data/collect/bulk/`)

| Type       | Items | Endpoint collecte         | Status sync |
|------------|-------|---------------------------|-------------|
| SMS        | 120   | `/api/v1/data/collect/bulk/` (data_type=messages) | ✅ `processed_count: 100 + 20`, `error_count: 0` |
| Calls      | 48    | `/api/v1/data/collect/bulk/` (data_type=calls)    | ✅ mais NON uploadé dans les batches observés (seul le `[Calls] Bootstrap completed: 48 historical calls captured` est loggué) |
| app_info   | 158   | `/api/v1/data/collect/bulk/` (data_type=app_info) | ✅ `processed_count: 100 + 58`, `error_count: 0` |
| app_usage  | 24    | `/api/v1/data/collect/bulk/` (data_type=app_usage)| ✅ `processed_count: 24`, `error_count: 0` |
| media_meta | 45    | `/api/v1/data/collect/bulk/` (data_type=media)    | ✅ `processed_count: 45`, `error_count: 0` |
| location   | 0     | —                         | 🔴 `System location services disabled. Collection paused until re-enabled.` |

### Permissions finales côté device (à la fin de l'exécution)
| Permission     | État   | Impact côté app surveillante |
|----------------|--------|------------------------------|
| sms            | granted | ✅ SMS visibles |
| call_log       | granted | ✅ Calls visibles — **mais aucun batch `calls` n'a été POSTé** dans les 2 batches observés ; les 48 calls restent en file d'attente locale (`[Calls] Queued ... for sync with priority 2` x48, supprimés du présent log) |
| storage        | granted | ✅ Media accessibles |
| media_images   | granted | ✅ |
| media_video    | granted | ✅ |
| media_audio    | granted | ✅ |
| camera         | granted | (non utilisé pour l'instant) |
| microphone     | granted | (non utilisé pour l'instant) |
| contacts       | granted | ✅ |
| **location**   | **denied** | 🔴 **Position non collectée** — Discordance avec `location_enabled: true` côté payload PATCH |

### Pistes à investiguer côté app surveillante (Flutter/Django)

1. **Calls** : Le bootstrap a capturé 48 calls et les a queueés (priority 2) mais aucun batch `calls` n'apparaît dans les 2 POST `/collect/bulk/`. Causes possibles : chunking, plafond de 100 items/batch (le `calls` aurait dû être inclus — vérifier le code du `BulkDataCollector` côté Flutter et le sérialiseur côté Django `MessageSerializer` vs `CallSerializer`), ou un filtre d'exclusion par type. → Vérifier [`debug docs/FIX_FRONTEND_BULK_COLLECT_CHUNKING_20260516.md`](./FIX_FRONTEND_BULK_COLLECT_CHUNKING_20260516.md).
2. **Location** : `permissions_status.location = denied` dans le 2nd PATCH, alors que `location_enabled: true`. Le collecteur reste bloqué (`System location services disabled`). → Vérifier que l'app surveillante ne tombe pas dans un état d'attente infini quand la config backend dit `enabled: true` mais que la permission runtime est `denied`.
3. **Media** : 45 items uploadés avec succès (`processed_count: 45, error_count: 0`). Si l'app surveillante n'affiche pas les médias, le problème est en aval (rendu, endpoint de lecture `/api/v1/data/media/` Django, ou cache frontend).
4. **Apps** : 158 items `app_info` + 12 items `app_usage` (24 envoyés, mais `app_usage: Processed 12 items` + 12 autres comptés dans la queue). `checkGetInstalledAppsPermissionStatus ret:-2` n'a pas empêché la collecte — à vérifier si l'app surveillante reçoit bien la liste complète.
5. **display_mode** : aucun événement WebSocket entrant n'a changé le mode après l'init `NORMAL`. Si l'app surveillante a un bouton "Passer en DISCRETE", ce bouton n'a pas été testé pendant cette session d'enregistrement des logs.
6. **Dual isolate** : un `startCollectors() skipped: another isolate owns collection` apparaît 2 fois (background isolate au redémarrage) — cohérent avec [`debug docs/MONITORED_APP_ISSUE_DUAL_ISOLATE_COLLECTOR_RACE_20260512.md`](./MONITORED_APP_ISSUE_DUAL_ISOLATE_COLLECTOR_RACE_20260512.md). Pas d'erreur 5xx, mais à surveiller.

---

## 13. Annexe — éléments supprimés (doublons ou bruit) — représentatif

- **ViewTreeObserver** : ~70 lignes identiques `W/ViewTreeObserver(21089): onPreDraw return false io.flutter.embedding.android.FlutterActivityAndFragmentDelegate$2@2ee3638` → 1 ligne conservée en note.
- **ApkAssets** : ~80 lignes `W/t.monitored_app(21089): ApkAssets: Deleting an ApkAssets object '<empty> and /...'` → aucune conservée (bruit pur du GC Android).
- **InputMethodManager / ImeFocusController / ImeTracker / Imetracker** : ~40 lignes (cycles show/hide clavier) → aucune conservée.
- **SurfaceControl / BufferQueueConsumer / BufferQueueProducer** : ~120 lignes (cycles SurfaceView FlutterView) → aucune conservée.
- **RtgSchedIpcFile** : ~30 lignes identiques `E/RtgSchedIpcFile(21089): RtgSchedIpcFile xxx failed to open /proc/21089/rtg` → aucune conservée.
- **Choreographer `Skipped N frames`** : 5 occurrences (`60 frames`, `269 frames`, `69 frames`, `32 frames`, `454 frames`, `61 frames`, `86 frames`, `39 frames`, `74 frames`) → conservées uniquement celles qui suivent immédiatement un événement fonctionnel pertinent.
- **HiTouch_PressGestureDetector** : ~30 lignes d'interactions tactiles → aucune conservée.
- **`Sync status updated: idle`** : ~18 occurrences consécutives → 1 seule conservée.
- **`Sync status updated: completed`** : ~10 occurrences consécutives en fin de session → 1 seule conservée en note.
- **`Queued sms data for sync with priority 1/2`** : 60+60 lignes → aucune conservée, les totaux (`Processed 60 items`, `Sync completed: 120 sms items`) suffisent.
- **`Queued app_info data for sync with priority 3`** : ~158 lignes → aucune conservée, total `Collected and stored 158 installed apps` conservé.
- **`Queued app_usage data for sync with priority 3`** : ~12 lignes + **24 lignes priority 2** (re-queue) → aucune conservée, total `App usage periodic check complete: 12 new records` + `Sync completed: 24 app_usage items` conservé.
- **`Queued calls data for sync with priority 2`** : 48 lignes → aucune conservée, total `Calls: Processed 48 items` + `Sync completed: 48 items` (uniquement si confirmé dans un batch ultérieur).
- **`Advanced media configuration updated / Media collection optimized`** : 4 occurrences identiques → 1 conservée.
- **Window state changed / View clicked AccessibilityMonitoring** : ~20 transitions de fenêtres système → condensées en 1 note narrative.
