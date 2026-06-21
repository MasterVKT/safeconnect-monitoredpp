# Logs App Surveillée — Épurés

**Date d'exécution** : 2026-06-17
**Appareil** : HONOR GFY-LX2 (Android 14, API 34)
**Device ID post-pairing** : `9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721`
**Backend** : `http://192.168.1.127:8000/api/v1`
**Période des logs** : Session complète incluant pairing, collectors bootstrap, et sync bulk initiale
**PID** : 4100

---

## Éléments supprimés et justifications

| Catégorie | Éléments supprimés | Raison |
|---|---|---|
| **SurfaceControl** | Toutes les entrées `I/SurfaceControl` (nativeRelease, ~SurfaceControl, animation-leash, Bounds, SurfaceView, StatusBar, NavigationBar, InputMethod) | Gestion UI Android interne, sans rapport avec les données |
| **InputMethodManager** | Toutes les entrées `I/InputMethodManager`, `V/InputMethodManager`, `D/InputMethodManager`, `W/InputMethodManager`, `I/ImeTracker` | Gestion clavier Android interne |
| **ApkAssets** | Blocs massifs ~250 lignes `W/t.monitored_app: ApkAssets: Deleting...` (2 occurrences) | Nettoyage mémoire Android système |
| **HiTouch_PressGestureDetector** | `I/HiTouch_PressGestureDetector`, `W/HiTouch_PressGestureDetector` | Détection gestes tactiles |
| **Choreographer** | `I/Choreographer: Skipped X frames!` | Performance UI générale |
| **FlutterAnimationAdvance** | `W/FlutterAnimationAdvance getInstance()` | Animation Flutter interne |
| **FlutterWebRTCPlugin** | `W/FlutterWebRTCPlugin: audioFocusChangeListener` | Audio focus WebRTC |
| **ViewTreeObserver** | `W/ViewTreeObserver: onPreDraw return false` | Bruit standard Flutter/Android |
| **SurfaceView** | `I/SurfaceView: updateSurface / setWindowStopped / REL / create` | Gestion surface d'affichage Android |
| **BufferQueueProducer/Consumer** | `I/BufferQueueProducer: connect/disconnect`, `I/BufferQueueConsumer` | File de buffers graphiques |
| **VRI[MainActivity]** | `I/VRI[MainActivity]: send MSG_WINDOW_FOCUS_CHANGED msg` | Focus fenêtre |
| **ImeBackDispatcher / WindowOnBackDispatcher** | Gestion touche retour IME | Gestion système |
| **RtgSched / RmeSched** | `E/RtgSchedIpcFile`, `I/RmeSchedManager`, `D/RtgSched` | Scheduling système Huawei |
| **SessionLifecycleService/Client** | `D/SessionLifecycleService`, `D/SessionLifecycleClient`, `D/SessionFirelogPublisher` | Cycle de vie session Firebase |
| **FA (Firebase Analytics)** | `I/FA: Application backgrounded at...` | Analytics interne |
| **HwCust / FlutterJNI / ResourceExtractor / libMEOW / FLTFireContextHolder** | Lignes de bruit système Flutter/Huawei | Initialisation plateforme |
| **ActivityThread** | `D/ActivityThread: Won't deliver top position change` | Cycle d'activité Android |
| **HnContentRecognizer / ContentDeliverer** | `D/HnContentRecognizerManager`, `I/ContentDelivererImpl` | Reconnaissance contenu Huawei |
| **DecorView** | `I/DecorView[]: set decor visibility` | Visibilité décoration fenêtre |
| **ImeFocusController** | `V/ImeFocusController: onWindowFocus` | Focus IME |
| **GC memory** | `I/t.monitored_app: Background concurrent mark compact GC freed...`, `Reducing the number of considered missed Gc histogram windows` | Garbage collector Android |
| **AccessibilityMonitoring** | `D/AccessibilityMonitoring: Window state changed / View clicked / Notification from` | Monitoring accessibilité |
| **PerformancePlugin** | `W/PerformancePlugin: CPU global metrics unavailable` | Métriques CPU |
| **AudioCapabilities/VideoCapabilities** | `W/AudioCapabilities: Unsupported mime`, `W/VideoCapabilities: Unrecognized profile/level`, `Unsupported mime` | Codecs WebRTC |
| **nativeloader** | `D/nativeloader: Load ...so using ns` | Chargement bibliothèques natives |
| **CompatibilityChangeReporter** | `D/CompatibilityChangeReporter: Compat change id reported` | Changements compatibilité Android |
| **HwForceDarkManager / HwViewRootImpl / Hwaps / HwApsManager / HwFrameworkSecurityPartsFactory** | Lignes système Huawei diverses | Bruit matériel Huawei |
| **PointerIcon / PhoneWindow / InsetsController** | `I/PointerIcon`, `I/PhoneWindow`, `I/InsetsController` | Gestion UI système |
| **OpenGLRenderer** | `E/OpenGLRenderer: Unable to match the desired swap behavior` | Rendu graphique |
| **skia** | `D/skia: purge small` | Cache graphique |
| **StubController** | `I/StubController: system app validUid...` | Contrôle système |
| **ScrollIdentify** | `I/ScrollIdentify: on fling` | Détection défilement |
| **InstallationId** | `W/InstallationId: Error getting authentication token` + stack trace | Erreur interne Firebase, doublon de l'erreur FCM |
| **AssistStructure** | `I/AssistStructure: Flattened final assist data` | Structure d'assistance Android |
| **libfluency_jni** | `D/nativeloader: Load libfluency_jni.so` | Chargement bibliothèque clavier |
| **IMS (InputMethod)** | Toutes lignes restantes IME/IMS | Gestion clavier |

---

## Doublons consolidés

| Message original | Occurrences | Conservation |
|---|---|---|
| `Sync status updated: idle` | ~15+ (dispersées) | 1 occurrence + annotation `[×N]` |
| `Sync status updated: syncing` | 3 | 1 occurrence + annotation `[×3]` |
| `Sync status updated: completed` | ~10+ | 1 occurrence + annotation `[×N]` |
| `Advanced media configuration updated: high quality, light compression` / `Media collection optimized for 5000kbps bandwidth` | ~8+ (bloc de 2 lignes dispersé) | 1 occurrence du bloc + annotation `[×N]` |
| `WebSocket: Received message type: device_status` | ~10+ (dispersées) | 1 occurrence + annotation `[×N]` |
| `Queued sms data for sync with priority 1` | 2 | 1 occurrence + annotation `[×2]` |
| `Queued calls data for sync with priority 2` | 2 (bootstrap + periodic) | 1 occurrence + annotation `[×2]` |
| `Queued location data for sync with priority 2` | 4 (dispersées) | 1 occurrence + annotation `[×4]` |
| `Queued app_usage data for sync with priority 2` | 7+ (consecutives) | 1 occurrence + annotation `[×7]` |
| `Location: Processed 1 items` | 3 | 1 occurrence + annotation `[×3]` |
| `Camera or storage permissions not granted` | 2 | 1 occurrence + annotation `[×2]` |
| `[DataCollector] stopCollectors() skipped: collectors not running` | 2 | 1 occurrence + annotation `[×2]` |
| `[DataCollector] startCollectors() skipped: collectors already running for main_isolate` | 2 | 1 occurrence + annotation `[×2]` |
| `[DataCollector] Collection lease unavailable for background_isolate` | 2 | 1 occurrence + annotation `[×2]` |
| `[DataCollector] startCollectors() skipped: another isolate owns collection` | 2 | 1 occurrence + annotation `[×2]` |
| `Background isolate: another isolate owns collection; keeping service alive` | 2 | 1 occurrence + annotation `[×2]` |
| `Enhanced battery status reported: 100%, charging: true/false, health: good` | 4 | 1 occurrence avec état initial |
| `Battery monitoring stopped` | 2 | 1 occurrence + annotation `[×2]` |
| `FCM token unavailable: unknown` | 2 | 1 occurrence + annotation `[×2]` |
| `DeviceService initialized successfully` | 2 (main + background) | 1 occurrence + annotation `[×2]` |
| `AppConfig initialized: env=dev...` | 2 (main + background) | 1 occurrence + annotation `[×2 - main + bg]` |
| `Database initialized with encryption` | 2 | 1 occurrence + annotation `[×2]` |
| `BatteryMonitorService initialized` | 2 | 1 occurrence + annotation `[×2]` |
| `SyncStatusMonitor initialized` | 2 | 1 occurrence + annotation `[×2]` |
| `No pending sync items found in database` | 2 | 1 occurrence + annotation `[×2]` |
| `WebSocket: Connected` | 1 (unique) | Conservée telle quelle |
| `Generated new session / Broadcasting new session / Notified CRASHLYTICS of new session` | Séquence Firebase sessions | 1 occurrence + annotation |
| `Skipped X frames!` | 271, 75, 30, 517, 96, 60, 37, 36 | Supprimées (toutes) |
| `E/FirebaseMessaging: Failed to get FIS auth token` (stack trace complet) | 2 (identique) | 1 occurrence + annotation `[×2]` |

---

## Logs épurés

```
=== LANCEMENT ===
Device: GFY LX2 (A2SJCP4A19414110) - android-arm64 - Android 14 (API 34)
Running Gradle task 'assembleDebug'...
√ Built build\app\outputs\flutter-apk\app-debug.apk
Installing build\app\outputs\flutter-apk\app-debug.apk...
Syncing files to device GFY LX2...
Dart VM Service at: http://127.0.0.1:50560/sme1C_Ocpqo=/

--- Rendu ---
I/flutter: Known bad Vulkan driver encountered, falling back to OpenGLES.
I/flutter: Using the Impeller rendering backend (OpenGLES).

--- Services : Initialisation ---
I/flutter: AppConfig initialized: env=dev, api=http://192.168.1.127:8000/api/v1, displayMode=NORMAL
I/flutter: Database initialized with encryption
I/flutter: Skipping SecurityService.initialize() in debug mode
I/flutter: Skipping EmergencyService.initialize() in debug mode
I/flutter: Skipping StealthService.initialize() in debug mode
I/flutter: Skipping AntiTamperService.initialize() in debug mode
I/flutter: Camera or storage permissions not granted  [×2]
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
I/flutter: Sync status updated: idle  [×N]
I/flutter: DeviceService initialization skipped: no authenticated session yet
I/flutter: PerformanceMonitor initialized
I/flutter: ConsentManager initialized with 0 active consents
I/flutter: P2P Communication Service initialized
I/flutter: P2P Signaling Service initialized
I/flutter: P2P Command Handler initialized
I/flutter: Loaded 4 ICE servers
I/org.webrtc.Logging: NativeLibrary: Loading native library: jingle_peerconnection_so
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

--- Firebase / FCM ---
D/SessionLifecycleService: Cold start detected.
D/SessionLifecycleService: Generated new session.
D/SessionLifecycleService: Broadcasting new session
D/SessionFirelogPublisher: Data Collection is enabled for at least one Subscriber
D/SessionLifecycleClient: Notified CRASHLYTICS of new session dbf2086dda9f492e86d284d54fdfbac8
D/EventGDTLogger: Session Event Type: SESSION_START
D/SessionFirelogPublisher: Successfully logged Session Start event.
W/InstallationId: Error getting authentication token.
W/InstallationId: Firebase Installations Service is unavailable. Please try again later.
 (stack trace complet: FirebaseInstallationsException)
E/FirebaseMessaging: Topic sync or token retrieval failed on hard failure exceptions: FIS_AUTH_ERROR. Won't retry the operation.
I/TRuntime.CctTransportBackend: Making request to: https://firebaselogging-pa.googleapis.com/v1/firelog/legacy/batchlog
I/TRuntime.CctTransportBackend: Status Code: 200

--- Bloc récurrent : Configuration média ---
(Bloc apparaît ~8× en dispersion : "Advanced media configuration updated: high quality, light compression" + "Media collection optimized for 5000kbps bandwidth")
  [×8]

=== PAIRING ===
I/flutter: Starting device pairing with code: 047530
I/flutter: [PAIRING] Starting device pairing process...
I/flutter: [PAIRING] Calling validate-pairing-code endpoint...
I/flutter: REQUEST[POST] => http://192.168.1.127:8000/api/v1/devices/validate-pairing-code/
I/flutter: DATA => {pairing_code: 047530, pairingCode: 047530, device_identifier: HONORGFY-L32, device_info: {platform: ANDROID, device_name: HONOR GFY-LX2, model: GFY-LX2, device_model: HONOR GFY-LX2, manufacturer: HONOR, device_id: HONORGFY-L32, os_version: 14, sdk_version: 34, app_version: 1.0.0-debug, app_build_number: 1}, deviceInfo: {platform: ANDROID, device_name: HONOR GFY-LX2, model: GFY-LX2, device_model: HONOR GFY-LX2, manufacturer: HONOR, device_id: HONORGFY-L32, os_version: 14, sdk_version: 34, app_version: 1.0.0-debug, app_build_number: 1}}

I/flutter: RESPONSE[200] => http://192.168.1.127:8000/api/v1/devices/validate-pairing-code/
I/flutter: DATA => {success: true, message: Jumelage réussi, device_id: 9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721, device: {id: 9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721, name: HONOR GFY-LX2, device_name: HONOR GFY-LX2, device_identifier: HONORGFY-L32, platform: ANDROID, model: HONOR GFY-LX2, device_model: HONOR GFY-LX2, os_version: 14, is_monitored: true, is_monitoring: false, last_seen: 2026-06-17T13:46:24.571480Z, last_sync: 2026-06-17T13:46:24.571480Z, is_online: false, battery_level: null, is_charging: false, created_at: 2026-06-07T02:41:52.318902Z, updated_at: 2026-06-17T13:44:23.594861Z, user: {id: 1c1261a0-819e-49c1-a236-48d7c03aa942, email: ericvekout@gmail.com, full_name: Eric Vekout}, status: OFFLINE, monitored_by: [{device_id: 29aeccd6-dd5f-48ba-93ef-373ae07ba4e6, device_name: Mon appareil (en cours de jumelage), user: {id: 1c1261a0-819e-49c1-a236-48d7c03aa942, email: ericvekout@gmail.com, full_name: Eric Vekout}, permission_type: FULL_ACCESS, granted_at: 2026-06-17T17:34:19.958344+00:00}], monitoring: [], display_mode: ...

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
I/flutter: [DataCollector] Stopping prior collectors due to permission change
I/flutter: [DataCollector] stopCollectors() skipped: collectors not running  [×2]
I/flutter: Device pairing successful
I/flutter: [DataCollector] Restarting collectors after permission change
I/flutter: No pending sync items found in database  [×2]
I/flutter: No server configuration available, using defaults

=== COLLECTEURS : Initialisation post-pairing ===
--- SMS Collector ---
I/flutter: Initializing SMS collector
I/flutter: SMS: Required permissions not granted
I/flutter: [SMS] initialized with bootstrapPending=true, lastCheckTime=null
I/flutter: SMS collector initialized successfully

--- Calls Collector ---
I/flutter: Initializing Calls collector
I/flutter: Calls: Required permissions not granted
I/flutter: [Calls] initialized with bootstrapPending=true, lastCheckTime=null
I/flutter: Calls collector initialized successfully

--- Location Collector ---
I/flutter: Initializing Location collector
I/flutter: Location: Required permissions not granted
I/flutter: Location collector initialized successfully

--- Apps Collector ---
I/flutter: Initializing Apps collector
I/flutter: Apps: Required permissions not granted
I/flutter: Apps collector specific initialization completed
I/flutter: Apps collector initialized successfully

--- Media Collector ---
I/flutter: Camera or storage permissions not granted
I/flutter: [MediaStore] initialized with per-category bootstrap checkpoints

=== ÉTAT INITIAL DES PERMISSIONS ===
I/flutter: SMS: Cannot start collection - permissions not granted
I/flutter: Calls: Cannot start collection - permissions not granted
I/flutter: Location: Cannot start collection - permissions not granted
I/flutter: Apps: Cannot start collection - permissions not granted
I/flutter: [MEDIA] Cannot start media collection: permissions not granted
I/flutter: [MediaStore] Cannot start scan: media read permissions missing

=== COLLECTION CONFIG ===
I/flutter: REQUEST[GET] => http://192.168.1.127:8000/api/v1/data/collection-config/?device_id=9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721
I/flutter: DATA => null

I/flutter: RESPONSE[200] => http://192.168.1.127:8000/api/v1/data/collection-config/?device_id=9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721
I/flutter: DATA => {location: {enabled: true, interval_seconds: 900, accuracy: BALANCED}, messages: {enabled: true, types: [SMS, MMS, WHATSAPP, TELEGRAM, MESSENGER], include_content: true}, calls: {enabled: true, record_calls: false}, app_usage: {enabled: true, interval_minutes: 30}, media: {enabled: true, scan_interval_hours: 24, include_thumbnails: false}}
I/flutter: Collection configuration loaded: (location, messages, calls, app_usage, media)

=== DEVICE STATUS PATCH (Permissions refusées) ===
I/flutter: REQUEST[PATCH] => http://192.168.1.127:8000/api/v1/devices/devices/9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721/
I/flutter: DATA => {battery_level: 100, is_charging: true, is_online: true, last_sync: 2026-06-17T18:34:35.793303, storage_available: 1073741824, network_type: wifi, location_enabled: true, permissions_status: {location: denied, camera: denied, microphone: denied, contacts: denied, sms: denied, call_log: denied, storage: denied, media_images: denied, media_video: denied, media_audio: denied}, app_version: 1.0.0-debug, os_version: 14, device_model: HONOR GFY-LX2, device_name: HONOR GFY-LX2}

I/flutter: RESPONSE[200] => http://192.168.1.127:8000/api/v1/devices/devices/9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721/
I/flutter: DATA => {id: 9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721, name: HONOR GFY-LX2, device_name: HONOR GFY-LX2, device_identifier: HONORGFY-L32, platform: ANDROID, model: HONOR GFY-LX2, device_model: HONOR GFY-LX2, os_version: 14, is_monitored: true, is_monitoring: false, last_seen: 2026-06-17T18:34:35.793303Z, last_sync: 2026-06-17T18:34:35.793303Z, is_online: true, battery_level: 100, is_charging: true, created_at: 2026-06-07T02:41:52.318902Z, updated_at: 2026-06-17T17:34:24.836194Z, user: {id: 1c1261a0-819e-49c1-a236-48d7c03aa942, email: ericvekout@gmail.com, full_name: Eric Vekout}, status: ONLINE, monitored_by: [{device_id: 29aeccd6-dd5f-48ba-93ef-373ae07ba4e6, device_name: Mon appareil (en cours de jumelage), user: {id: 1c1261a0-819e-49c1-a236-48d7c03aa942, email: ericvekout@gmail.com, full_name: Eric Vekout}, permission_type: FULL_ACCESS, granted_at: 2026-06-17T17:34:19.958344+00:00}], monitoring: [], display_mode: NORMAL, fcm_token_registered: false}

I/flutter: Device status updated successfully

=== CONSENTEMENT ===
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

=== PERMISSIONS ACCORDÉES PAR L'UTILISATEUR → REDÉMARRAGE COLLECTEURS ===
I/flutter: [DataCollector] Stopping prior collectors due to permission change
I/flutter: [DataCollector] stopCollectors() skipped: collectors not running
I/flutter: [DataCollector] Restarting collectors after permission change

--- SMS Bootstrap ---
I/flutter: SMS specific collection started
I/flutter: SMS collector started with interval: 900 seconds
I/flutter: [SMS] Collection skipped: another collection is running
D/SmsCollectorPlugin: getNewSms query returned 102 rows since 1773941779321
I/flutter: [SMS] getNewSms returned 102 entries since 2026-03-19 18:36:19.321460 (bootstrap=true)
I/flutter: Queued sms data for sync with priority 1  [×2]
I/flutter: [SMS] Bootstrap completed: 102 historical SMS captured.
I/flutter: SMS: Processed 102 items
I/flutter: SMS periodic check complete: 102 new messages

--- Calls Bootstrap ---
I/flutter: Calls specific collection started
I/flutter: Calls collector started with interval: 900 seconds
I/flutter: [Calls] Collection skipped: another collection is running
I/flutter: [Calls] getNewCalls returned 57 entries since 2026-03-19 18:36:20.540332 (bootstrap=true)
I/flutter: Queued calls data for sync with priority 2  [×2]
I/flutter: [Calls] Bootstrap completed: 57 historical calls captured.
I/flutter: Calls: Processed 57 items
I/flutter: Calls periodic check complete: 57 new calls

--- Location ---
I/flutter: Location specific collection started with interval: 900 seconds
I/flutter: Location collector started with interval: 900 seconds
E/FlutterGeolocator: Geolocator position updates started

--- Apps Bootstrap ---
I/flutter: Apps specific collection started
I/flutter: Apps collector started with interval: 900 seconds
I/ApplicationPackageManager: checkGetInstalledAppsPermissionStatus,packageName:com.xpsafeconnect.monitored_app,ret:-2
I/flutter: Queued app_info data for sync with priority 3  [×1 première occurrence]
I/flutter: Collected and stored 289 installed apps
I/flutter: Queued app_usage data for sync with priority 2  [×7 consécutifs → apps usage periodique]

--- Media Bootstrap ---
I/flutter: Advanced media collector started with config: high

=== SYNCHRONISATION BULK ===

--- Bulk Phase 1 : messages + app_info ---
I/flutter: [BulkSync] Candidates: sms=204, app_info=289, app_usage=14, media_metadata=51, calls=57, location=3
I/flutter: Display mode changed to NORMAL
I/flutter: Notification mode changed to VISIBLE
I/flutter: REQUEST[POST] => http://192.168.1.127:8000/api/v1/data/collect/bulk/
I/flutter: DATA => {device_id: 9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721, data_batches: [{data_type: messages, items: [{message_type: SMS, direction: INCOMING, sender: MTN, sender_name: null, body: Bienvenue dans la communaute la plus incroyable, MTN YaMo! ..., sent_at: 2026-04-24T14:55:12.005, conversation_id: 1, has_attachment: false}, ... (100 items en batch)]}

--- Bulk Phase 1 : Réponse ---
I/flutter: RESPONSE[200] => http://192.168.1.127:8000/api/v1/data/collect/bulk/
I/flutter: DATA => {success: true, partial_success: false, device_id: 9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721, processed_batches: 2, successful_batches: 2, failed_batches: 0, results: [{data_type: messages, result: {success: true, processed_count: 100, error_count: 0, batch_id: bd146b2d-95d1-4e40-8247-67b3a54399c5, device_id: 9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721, data_type: messages, item_errors: []}}, {data_type: app_info, result: {success: true, processed_count: 100, error_count: 0, batch_id: 53658d8f-88bb-4487-b5c7-130119749875, device_id: 9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721, data_type: app_info, item_errors: []}}]}

I/flutter: Enhanced battery status reported: 100%, charging: false, health: good (initial)
I/flutter: Switching to performance mode: maximum
I/flutter: Applied maximum performance mode

--- App backgrounded - Media scan effectué ---
I/flutter: [MediaStore] scanned 36 images items since 2026-03-19 18:36:29.211890 (bootstrap=true)
I/flutter: [MediaStore] images bootstrap completed: 36 items.
I/flutter: [MediaStore] scanned 2 videos items since 2026-03-19 18:36:29.509426 (bootstrap=true)
I/flutter: [MediaStore] videos bootstrap completed: 2 items.
I/flutter: [MediaStore] scanned 13 audio items since 2026-03-19 18:36:29.691169 (bootstrap=true)
I/flutter: [MediaStore] audio bootstrap completed: 13 items.

--- Bulk Phase 2 : messages + app_info (reste) + app_usage ---
I/flutter: Sync status updated: syncing  [×3]
I/flutter: REQUEST[POST] => http://192.168.1.127:8000/api/v1/data/collect/bulk/
I/flutter: DATA => {device_id: 9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721, data_batches: [{data_type: messages, items: [{message_type: SMS, direction: INCOMING, sender: MoMoSecure, ..., sent_at: 2026-06-17T10:31:07.869, conversation_id: 26, has_attachment: false}, ... (4 items restants du SMS)]}

--- Bulk Phase 2 : Réponse ---
I/flutter: RESPONSE[200] => http://192.168.1.127:8000/api/v1/data/collect/bulk/
I/flutter: DATA => {success: true, partial_success: false, device_id: 9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721, processed_batches: 5, successful_batches: 5, failed_batches: 0, results: [{data_type: messages, result: {success: true, processed_count: 4, error_count: 0, batch_id: cc8dd9ec-8cfd-4bbc-a3b3-e996a94f7868, ...}}, {data_type: app_info, result: {success: true, processed_count: 89, error_count: 0, batch_id: 4d667f38-2ba9-4bd1-b521-8b6df43041b2, ...}}, {data_type: app_usage, result: {success: true, processed_count: 14, error_count: 0, batch_id: 50dc8b46-77eb-4839-8898-8aa555d35f9e, ...}}, {data_type: media, result: {success: true, processed_count: 51, error_count: 0, batch_id: 55d393ab-cc9a-4c04-a2ae-4aaed11f7373, ...}}, {data_type: calls, result: {success: true, processed_count: 57, error_count: 0, batch_id: 19bb41a0-071e-4e1f-a6dc-0f9093d13537, ...}}]}

--- Bulk calls (57 items) ---
I/flutter: REQUEST[POST] => http://192.168.1.127:8000/api/v1/data/collect/bulk/
I/flutter: DATA => {device_id: 9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721, data_batches: [{data_type: calls, items: [{call_type: OUTGOING, phone_number: 698841974, contact_name: Eric Vekout, start_time: 2026-04-24T13:56:06.376Z, end_time: null, duration: 0, ...}, {call_type: OUTGOING, phone_number: 674561844, contact_name: Frigoriste, start_time: 2026-04-24T14:15:11.592Z, end_time: null, duration: 0, ...}, {call_type: OUTGOING, phone_number: 674561844, contact_name: Frigoriste, start_time: 2026-04-24T14:56:08.129Z, end_time: 2026-04-24T14:56:55.129Z, duration: 47, ...}, ... (57 items)]}

--- Bulk calls : Réponse ---
I/flutter: RESPONSE[200] => http://192.168.1.127:8000/api/v1/data/collect/bulk/
I/flutter: DATA => {success: true, partial_success: false, device_id: 9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721, processed_batches: 1, successful_batches: 1, failed_batches: 0, results: [{data_type: calls, result: {success: true, processed_count: 57, error_count: 0, batch_id: 19bb41a0-071e-4e1f-a6dc-0f9093d13537, ...}}]}

--- Device status PATCH (Permissions accordées) ---
I/flutter: REQUEST[PATCH] => http://192.168.1.127:8000/api/v1/devices/devices/9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721/
I/flutter: DATA => {battery_level: 100, is_charging: true, is_online: true, last_sync: 2026-06-17T18:36:40.289588, storage_available: 1073741824, network_type: wifi, location_enabled: true, permissions_status: {location: denied, camera: granted, microphone: granted, contacts: granted, sms: granted, call_log: granted, storage: granted, media_images: granted, media_video: granted, media_audio: granted}, app_version: 1.0.0-debug, os_version: 14, device_model: HONOR GFY-LX2, device_name: HONOR GFY-LX2}

I/flutter: RESPONSE[200] => http://192.168.1.127:8000/api/v1/devices/devices/9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721/
I/flutter: DATA => {id: 9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721, name: HONOR GFY-LX2, ..., status: ONLINE, display_mode: NORMAL, fcm_token_registered: false}

I/flutter: Device status updated successfully

--- Bilan Sync complet ---
I/flutter: Sync status updated: completed  [×N]
I/flutter: Sync completed: 204 sms items
I/flutter: Sync completed: 289 app_info items
I/flutter: Sync completed: 14 app_usage items
I/flutter: Sync completed: 51 media_metadata items
I/flutter: Sync completed: 3 location items
I/flutter: Sync completed: 57 calls items
I/flutter: Marked 618 items as synced
I/flutter: Optimized bulk sync completed: 6 types, 618 items

--- Location sync via endpoint non-bulk (3 items restants) ---
I/flutter: REQUEST[POST] => http://192.168.1.127:8000/api/v1/data/collect/
I/flutter: DATA => {device_id: 9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721, data_type: location, items: [{latitude: 4.0863402, longitude: 9.7657262, accuracy: 19.385000228881836, altitude: 64.0999984741211, speed: 0.0, heading: 0.0, recorded_at: 2026-06-17T18:36:30.182466, provider: gps, activity_type: UNKNOWN, collected_at: 2026-06-17T18:36:30.768601}, ... (3 items identiques)}], metadata: {collection_timestamp: 2026-06-17T18:36:41.717432, battery_level: 100, network_type: wifi, app_version: 1.0.0, batch_id: 8d7e1259-a900-4f14-b491-614fd5b9ae4a}

I/flutter: RESPONSE[200] => http://192.168.1.127:8000/api/v1/data/collect/
I/flutter: DATA => {success: true, processed_count: 3, error_count: 0, batch_id: 8d7e1259-a900-4f14-b491-614fd5b9ae4a, device_id: 9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721, data_type: location, latest_location: null, item_errors: []}
I/flutter: Marked 3 items as synced
I/flutter: Sync completed: 3 location items
I/flutter: Synced location batch: 3/3 items
I/flutter: No pending sync items found in database

=== FCM (répété en arrière-plan) ===
E/FirebaseMessaging: Failed to get FIS auth token
 (stack trace complet: FirebaseInstallationsException: Firebase Installations Service is unavailable)
  [×2 - main + background]
I/flutter: FCM token unavailable: unknown  [×2]

=== DEVICE SERVICE (initialisé deux fois : main + background) ===
I/flutter: DeviceService initialized successfully  [×2]

=== BACKGROUND ISOLATE (after restart) ===
I/flutter: Background service started
I/flutter: AppConfig initialized: env=dev, api=http://192.168.1.127:8000/api/v1, displayMode=NORMAL  [×2 - main + bg]
I/flutter: Database initialized with encryption  [×2]
I/flutter: BatteryMonitorService initialized  [×2]
I/flutter: SyncStatusMonitor initialized  [×2]
I/flutter: Media collection optimized for 5000kbps bandwidth
I/flutter: Enhanced battery monitoring started
I/flutter: Auto start enabled
I/flutter: Initial configuration saved
I/flutter: Battery monitoring stopped  [×2]

--- Conflit d'isolates ---
I/flutter: [DataCollector] Collection lease unavailable for background_isolate  [×2]
I/flutter: [DataCollector] startCollectors() skipped: another isolate owns collection  [×2]
I/flutter: Background isolate: another isolate owns collection; keeping service alive  [×2]
I/flutter: Main isolate received: service_started

--- WebSocket heartbeats (dispersés) ---
I/flutter: WebSocket: Received message type: device_status  [×N]

=== FIN DE SESSION ===
I/flutter: Enhanced battery status reported: 100%, charging: false, health: good
I/flutter: Enhanced battery monitoring started
I/flutter: Enhanced battery status reported: 100%, charging: true, health: good
Application finished.
```

---

## Résumé des données collectées vs synchronisées

| Type de données | Collecté | Synchronisé | Statut |
|---|---|---|---|
| SMS | 102 (bootstrap) | 204 (2 batches: 100 + 4, avec ré-envoi) | ✅ OK (doublon apparent) |
| App info | 289 | 189 (100 + 89) | ⚠️ Partiel (189/289 synchronisé) |
| App usage | 14 | 14 | ✅ OK |
| Media metadata | 51 (36 img + 2 vid + 13 audio) | 51 | ✅ Métadonnées OK |
| Location | 3+3 = 6 | 6 (3 bulk + 3 non-bulk) | ⚠️ Permission `denied` mais collecté via GPS |
| **Calls** | **57** | **57** | **✅ OK** |
| **FCM Token** | — | — | **🔴 ÉCHEC** (`fcm_token_registered: false`) |

### Anomalies notables

1. **Permissions initialement toutes refusées** → collecte impossible au démarrage.
2. **Permissions accordées progressivement** → redémarrage des collecteurs.
3. **Location: permission `denied`** dans les deux PATCH de device status → les données GPS ont tout de même été collectées.
4. **FCM Token** : échec permanent `Firebase Installations Service unavailable` → pas de push notifications.
5. **App info** : 289 collectés, seulement 189 synchronisés (100 + 89) → 100 items perdus ou en attente.
6. **Format des SMS** : `conversation_id` dans certains payloads, `thread_id` dans d'autres → incohérence potentielle côté backend.
7. **Location en doublon** : 3 items identiques envoyés dans bulk, 3 autres via endpoint non-bulk.
8. **Conflit d'isolates** : background_isolate ne peut pas collecter car main_isolate tient le lease.