# Logs App Surveillée — Épurés

**Date d'exécution** : 2026-06-12  
**Appareil** : HONOR GFY-LX2 (Android 14)  
**Device ID** : `9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721`  
**Backend** : `http://192.168.1.127:8000/api/v1`  
**Période des logs** : Session complète incluant sync initiale, re-démarrage, et tentative de sync des appels

---

## Éléments supprimés et justifications

| Catégorie | Éléments supprimés | Raison |
|---|---|---|
| **SurfaceControl** | Toutes les entrées `I/SurfaceControl` (nativeRelease, ~SurfaceControl, animation-leash) | Gestion UI Android interne, sans rapport avec les données |
| **InputMethodManager** | Toutes les entrées `I/InputMethodManager`, `V/InputMethodManager`, `D/InputMethodManager`, `W/InputMethodManager` | Gestion clavier Android interne |
| **ApkAssets** | Bloc massif ~200 lignes `W/t.monitored_app: ApkAssets: Deleting...` | Nettoyage mémoire Android système, aucun impact sur les données collectées |
| **HiTouch** | `I/HiTouch_PressGestureDetector` | Détection gestes tactiles, sans rapport |
| **Choreographer** | `I/Choreographer: Skipped 60 frames!` | Performance UI générale |
| **FlutterAnimationAdvance** | `W/FlutterAnimationAdvance` | Animation Flutter interne |
| **FlutterWebRTCPlugin** | `W/FlutterWebRTCPlugin: audioFocusChangeListener` | Audio focus WebRTC, sans rapport avec collecte |
| **FlutterGeolocator** | `D/FlutterGeolocator` (3 lignes init) | Initialisation interne geolocator |
| **HwCust / FlutterJNI / ResourceExtractor / libMEOW / FLTFireContextHolder** | Lignes D/W de bruit système Flutter/Huawei | Initialisation plateforme, sans impact |
| **RtgSched / RmeSched / ActivityThread / HnContentRecognizer / DecorView / ContentDeliverer / SessionLifecycle / StubController / ImeFocusController** | Lignes système Android diverses | Bruit interne Android, sans rapport |
| **FA (Firebase Analytics)** | `I/FA: Application backgrounded` | Analytics interne |
| **GC memory** | `I/t.monitored_app: Background concurrent mark compact GC freed...` | Garbage collector Android |
| **AccessibilityMonitoring** | `D/AccessibilityMonitoring: Window state changed / Notification from...` | Monitoring accessibilité, sans rapport direct |

## Doublons consolidés

| Message original | Occurrences | Représentation conservée |
|---|---|---|
| `Queued calls data for sync with priority 2` | 51 fois (lignes 634-684) | 1 occurrence + annotation `[×51]` |
| `Queued location data for sync with priority 2` | 6 fois (lignes 52-59) | 1 occurrence + annotation `[×6]` |
| `Location: Processed 1 items` | 3 fois (lignes 56, 58, 60) | 1 occurrence + annotation `[×3]` |
| `WebSocket: Received message type: device_status` | 10+ fois | 1 occurrence + annotation `[×10+]` |
| `Sync status updated: completed` | 8+ fois | 1 occurrence + annotation `[×8+]` |
| `Sync status updated: idle` | 2 fois | 1 occurrence + annotation `[×2]` |
| `Enhanced battery status reported` | 4 fois | 1 occurrence avec état final |
| `Enhanced battery monitoring started` | 2 fois | 1 occurrence |
| `Battery monitoring stopped` | 2 fois | 1 occurrence |
| `[DataCollector] Collection lease unavailable for background_isolate` | 2 fois | 1 occurrence + annotation `[×2]` |
| `[DataCollector] startCollectors() skipped: another isolate owns collection` | 2 fois | 1 occurrence + annotation `[×2]` |
| `Background isolate: another isolate owns collection; keeping service alive` | 2 fois | 1 occurrence + annotation `[×2]` |

---

## Logs épurés

```
I/flutter (26530): Queued app_info data for sync with priority 3
I/flutter (26530): Collected and stored 159 installed apps
I/flutter (26530): Queued app_usage data for sync with priority 3

--- App passée en arrière-plan ---
I/flutter (26530): Advanced media collector started with config: medium
I/flutter (26530): Queued app_usage data for sync with priority 2

--- App usage periodic check ---
I/flutter (26530): Apps: Processed 10 items
I/flutter (26530): App usage periodic check complete: 10 new records

--- MediaStore bootstrap ---
I/flutter (26530): [MediaStore] scanned 30 images items since 2026-03-14 05:26:06.332462 (bootstrap=true)
I/flutter (26530): [MediaStore] images bootstrap completed: 30 items.
I/flutter (26530): [MediaStore] scanned 2 videos items since 2026-03-14 05:26:06.473660 (bootstrap=true)
I/flutter (26530): [MediaStore] videos bootstrap completed: 2 items.
I/flutter (26530): [MediaStore] scanned 13 audio items since 2026-03-14 05:26:06.510641 (bootstrap=true)
I/flutter (26530): [MediaStore] audio bootstrap completed: 13 items.

--- Bulk Sync : Phase 1 (SMS + App_info uniquement) ---
I/flutter (26530): Sync status updated: syncing
I/flutter (26530): [BulkSync] Candidates: sms=138, app_info=159, app_usage=20, media_metadata=45
I/flutter (26530): REQUEST[POST] => http://192.168.1.127:8000/api/v1/data/collect/bulk/
I/flutter (26530): DATA => {device_id: 9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721, data_batches: [{data_type: messages, items:
[{message_type: SMS, direction: INCOMING, sender: MTN, sender_name: null, body: Bienvenue dans la communaute la plus incroyable, MTN
YaMo! Tu es proche de gagner une bourse de 50 000F. Inscris toi VITE sur yamo.mtn.cm., sent_at: 2026-04-24T14:55:12.005,
conversation_id: 1, has_attachment: false}, {message_type: SMS, direction: INCOMING, sender: WhatsApp, sender_name: null, body: <#>
Code WhatsApp : 883-282
Ne partagez pas ce code
4sgLq1p5sV6, sent_at: 2026-04-24T19:20:14.319, conversation_id: 2, has_attachment: false}, {message_type: SMS,
direction: INCOMING, sender: MTN, sender_name: null, body: Oups ! Nous avons des difficultes a vous connecter sur Internet. Consultez
votre solde Internet pour confirmer que vous avez encore du volume : *123*99#, sent_at: 2026-04-25T00:13:47.690, conversation_id: 1,
has_attachment: false}, {message_type: SMS, direction: INCOMING, sender: Reviens, sender_name: null, body: PR
...
(truncated in original log — batch continues)

--- Location collectors en parallèle (×6 items) ---
I/flutter (26530): Queued location data for sync with priority 2  [×6]
I/flutter (26530): Location: Processed 1 items  [×3]

--- Bulk Sync : Réponse Phase 1 ---
I/flutter (26530): RESPONSE[200] => http://192.168.1.127:8000/api/v1/data/collect/bulk/
I/flutter (26530): DATA => {success: true, partial_success: false, device_id: 9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721, processed_batches:
2, successful_batches: 2, failed_batches: 0, results: [{data_type: messages, result: {success: true, processed_count: 100, error_count:
0, batch_id: acdd6a44-1ce9-4105-8a04-84ce94b186af, device_id: 9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721, data_type: messages, item_errors:
[]}}, {data_type: app_info, result: {success: true, processed_count: 100, error_count: 0, batch_id:
1bbe73ff-488c-4b51-8ef4-6beae36a392c, device_id: 9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721, data_type: app_info, item_errors: []}}]}

--- Bulk Sync : Phase 2 (SMS + App_info + App_usage + Media) ---
I/flutter (26530): REQUEST[POST] => http://192.168.1.127:8000/api/v1/data/collect/bulk/
I/flutter (26530): DATA => {device_id: 9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721, data_batches: [{data_type: messages, items:
[{message_type: SMS, direction: INCOMING, sender: MTN, body: Oups ! Nous avons des difficultes a vous connecter sur Internet. Consultez
votre solde Internet pour confirmer que vous avez encore du volume : *123*99#, sent_at: 2026-05-10T00:00:34.151, thread_id: 1,
has_attachment: false, collected_at: 2026-06-12T05:26:00.826054}, {message_type: SMS, direction: INCOMING, sender: Imbattable, body:
Rapprochez-vous de vos proches grace a nos forfaits voix ! Decouvrez nos offres d'appels personnalisees, faites pour vous, en composant
*222#, sent_at: 2026-05-10T08:01:45.752, thread_id: 10, has_attachment: false, collected_at: 2026-06-12T05:26:00.826054},
{message_type: SMS, direction: INCOMING, sender: WeekendDose, body: Arrete de reviser au hasard. Passe aux vraies epreuves du BAC sur
Youscribe a 100F + 7 jours illimites + 1 Go offert aux 1000 premiers, sent_at: 2026-05-10T12:39:06.877, thread_id: 4, has_attachment:
...
(truncated in original log — batch continues)

--- Bulk Sync : Réponse Phase 2 ---
I/flutter (26530): RESPONSE[200] => http://192.168.1.127:8000/api/v1/data/collect/bulk/
I/flutter (26530): DATA => {success: true, partial_success: false, device_id: 9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721, processed_batches:
4, successful_batches: 4, failed_batches: 0, results: [{data_type: messages, result: {success: true, processed_count: 38, error_count:
0, batch_id: 54d380d1-8d5e-482a-a585-4eb9382ae360, device_id: 9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721, data_type: messages, item_errors:
[]}}, {data_type: app_info, result: {success: true, processed_count: 59, error_count: 0, batch_id:
e5e2199d-b48b-4ec9-a1fa-5de425836819, device_id: 9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721, data_type: app_info, item_errors: []}},
{data_type: app_usage, result: {success: true, processed_count: 20, error_count: 0, batch_id: 98969620-13eb-4040-9f26-1097d5c9f233,
device_id: 9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721, data_type: app_usage, item_errors: []}}, {data_type: media, result: {success: true,
processed_count: 45, error_count: 0, batch_id: aa0d4bf2-e0b8-4ede-9d10-d18c614e3d97, device_id: 9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721,
data_type: media, item_errors: []}}]}

--- Bilan sync bulk ---
I/flutter (26530): Sync status updated: completed  [×8+ — une par type + marginales]
I/flutter (26530): Sync completed: 138 sms items
I/flutter (26530): Sync completed: 159 app_info items
I/flutter (26530): Sync completed: 20 app_usage items
I/flutter (26530): Sync completed: 45 media_metadata items
I/flutter (26530): Marked 362 items as synced
I/flutter (26530): Optimized bulk sync completed: 4 types, 362 items
I/flutter (26530): Loaded 6 pending items to collector (1 types)

--- WebSocket heartbeat ---
I/flutter (26530): WebSocket: Received message type: device_status  [×10+ tout au long de la session]

--- Follow-up sync : 6 items Location via endpoint non-bulk ---
I/flutter (26530): [DataCollector] Follow-up sync: flushing remaining 6 items
I/flutter (26530): Sync status updated: syncing
I/flutter (26530): REQUEST[POST] => http://192.168.1.127:8000/api/v1/data/collect/
I/flutter (26530): DATA => {device_id: 9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721, data_type: location, items: [{latitude: 4.08621,
longitude: 9.7659079, accuracy: 21.96299934387207, altitude: 69.5999984741211, speed: 0.0, bearing: null, recorded_at:
2026-06-12T05:26:07.277142, provider: gps, activity_type: null, battery_level: null}, {latitude: 4.08621, longitude: 9.7659079,
accuracy: 21.96299934387207, altitude: 69.5999984741211, speed: 0.0, bearing: null, recorded_at: 2026-06-12T05:26:07.317842, provider:
gps, activity_type: null, battery_level: null}, {latitude: 4.08621, longitude: 9.7659079, accuracy: 21.96299934387207, altitude:
69.5999984741211, speed: 0.0, bearing: null, recorded_at: 2026-06-12T05:26:07.329414, provider: gps, activity_type: null,
battery_level: null}, {latitude: 4.08621, longitude: 9.7659079, accuracy: 21.96299934387207, altitude: 69.5999984741211, speed: 0.0,
heading: 0.0, recorded_at: 2026-06-12T05:26:07.277142, provider: gps, activity_type: UNKNOWN, collected_at:
2026-06-12T05:26:07.339259}, {latitude: 4.
(truncated in original log)

I/flutter (26530): RESPONSE[200] => http://192.168.1.127:8000/api/v1/data/collect/
I/flutter (26530): DATA => {success: true, processed_count: 6, error_count: 0, batch_id: 7ab02431-7391-4c12-853b-d870949298e5,
device_id: 9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721, data_type: location, latest_location: 2da7d852-2b53-40ec-8a47-70b123618df3,
item_errors: []}
I/flutter (26530): Marked 6 items as synced
I/flutter (26530): Sync status updated: completed
I/flutter (26530): Sync completed: 6 location items
I/flutter (26530): Synced location batch: 6/6 items
I/flutter (26530): No pending sync items found in database
I/flutter (26530): Sync status updated: idle  [×2]

--- ═══════════════════════════════════════════════════════════════
     RE-DÉMARRAGE DE L'APPLICATION (nouveau processus Flutter)
     ═══════════════════════════════════════════════════════════════ ---

I/flutter (26530): Background service started
I/flutter (26530): Enhanced battery status reported: 100%, charging: false, health: good
I/flutter (26530): Switching to performance mode: maximum
I/flutter (26530): Applied maximum performance mode
I/flutter (26530): Enhanced battery status reported: 100%, charging: true, health: good
I/flutter (26530): Enhanced battery monitoring started

--- Initialisation des services ---
I/flutter (26530): AppConfig initialized: env=dev, api=http://192.168.1.127:8000/api/v1, displayMode=NORMAL
I/flutter (26530): Database initialized with encryption
I/flutter (26530): BatteryMonitorService initialized
I/flutter (26530): SyncStatusMonitor initialized
I/flutter (26530): Sync status updated: completed

--- Chargement de la configuration de collecte ---
I/flutter (26530): REQUEST[GET] =>
http://192.168.1.127:8000/api/v1/data/collection-config/?device_id=9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721
I/flutter (26530): DATA => null
I/flutter (26530): RESPONSE[200] =>
http://192.168.1.127:8000/api/v1/data/collection-config/?device_id=9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721
I/flutter (26530): DATA => {location: {enabled: true, interval_seconds: 900, accuracy: BALANCED}, messages: {enabled: true, types:
[SMS, MMS, WHATSAPP, TELEGRAM, MESSENGER], include_content: true}, calls: {enabled: true, record_calls: false}, app_usage: {enabled:
true, interval_minutes: 30}, media: {enabled: true, scan_interval_hours: 24, include_thumbnails: false}}
I/flutter (26530): Collection configuration loaded: (location, messages, calls, app_usage, media)

--- Mise à jour du statut appareil (PATCH) ---
I/flutter (26530): REQUEST[PATCH] => http://192.168.1.127:8000/api/v1/devices/devices/9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721/
I/flutter (26530): DATA => {battery_level: 100, is_charging: true, is_online: true, last_sync: 2026-06-12T05:26:43.423884,
storage_available: 1073741824, network_type: wifi, location_enabled: true, permissions_status: {location: denied, camera: granted,
microphone: granted, contacts: granted, sms: granted, call_log: granted, storage: granted, media_images: granted, media_video: granted,
media_audio: granted}, app_version: 1.0.0-debug, os_version: 14, device_model: HONOR GFY-LX2, device_name: HONOR GFY-LX2}
I/flutter (26530): RESPONSE[200] => http://192.168.1.127:8000/api/v1/devices/devices/9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721/
I/flutter (26530): DATA => {id: 9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721, name: HONOR GFY-LX2, device_name: HONOR GFY-LX2,
device_identifier: HONORGFY-L32, platform: ANDROID, model: HONOR GFY-LX2, device_model: HONOR GFY-LX2, os_version: 14, is_monitored:
true, is_monitoring: false, last_seen: 2026-06-12T05:26:43.423884Z, last_sync: 2026-06-12T05:26:43.423884Z, is_online: true,
battery_level: 100, is_charging: true, created_at: 2026-06-07T02:41:52.318902Z, updated_at: 2026-06-12T04:26:37.139305Z, user: {id:
1c1261a0-819e-49c1-a236-48d7c03aa942, email: ericvekout@gmail.com, full_name: Eric Vekout}, status: ONLINE, monitored_by: [{device_id:
29aeccd6-dd5f-48ba-93ef-373ae07ba4e6, device_name: Mon appareil (en cours de jumelage), user: {id:
1c1261a0-819e-49c1-a236-48d7c03aa942, email: ericvekout@gmail.com, full_name: Eric Vekout}, permission_type: FULL_ACCESS, granted_at:
2026-06-12T04:24:06.575700+00:00}], monitoring: [], display_mode: NORMAL, fcm_token_registered: false}
I/flutter (26530): Device status updated successfully

--- Erreur FCM Token ---
E/FirebaseMessaging(26530): Failed to get FIS auth token
E/FirebaseMessaging(26530): java.util.concurrent.ExecutionException: com.google.firebase.installations.FirebaseInstallationsException:
Firebase Installations Service is unavailable. Please try again later.
E/FirebaseMessaging(26530):     at com.google.android.gms.tasks.Tasks.zza(com.google.android.gms:play-services-tasks@@18.1.0:5)
E/FirebaseMessaging(26530):     at com.google.android.gms.tasks.Tasks.await(com.google.android.gms:play-services-tasks@@18.1.0:9)
E/FirebaseMessaging(26530):     at com.google.firebase.messaging.GmsRpc.setDefaultAttributesToBundle(GmsRpc.java:280)
E/FirebaseMessaging(26530):     at com.google.firebase.messaging.GmsRpc.startRpc(GmsRpc.java:242)
E/FirebaseMessaging(26530):     at com.google.firebase.messaging.GmsRpc.getToken(GmsRpc.java:192)
E/FirebaseMessaging(26530):     at com.google.firebase.messaging.FirebaseMessaging.lambda$blockingGetToken$14$com-google-firebase-messaging
-FirebaseMessaging(FirebaseMessaging.java:650)
E/FirebaseMessaging(26530):     at com.google.firebase.messaging.FirebaseMessaging$$ExternalSyntheticLambda14.start(D8$$SyntheticClass:0)
E/FirebaseMessaging(26530):     at com.google.firebase.messaging.RequestDeduplicator.getOrStartGetTokenRequest(RequestDeduplicator.java:67)
E/FirebaseMessaging(26530):     at com.google.firebase.messaging.FirebaseMessaging.blockingGetToken(FirebaseMessaging.java:646)
E/FirebaseMessaging(26530):     at com.google.firebase.messaging.FirebaseMessaging.lambda$getToken$7$com-google-firebase-messaging-Firebase
Messaging(FirebaseMessaging.java:420)
E/FirebaseMessaging(26530):     at com.google.firebase.messaging.FirebaseMessaging$$ExternalSyntheticLambda11.run(D8$$SyntheticClass:0)
E/FirebaseMessaging(26530):     at java.util.concurrent.Executors$RunnableAdapter.call(Executors.java:487)
E/FirebaseMessaging(26530):     at java.util.concurrent.FutureTask.run(FutureTask.java:264)
E/FirebaseMessaging(26530):     at
java.util.concurrent.ScheduledThreadPoolExecutor$ScheduledFutureTask.run(ScheduledThreadPoolExecutor.java:307)
E/FirebaseMessaging(26530):     at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1145)
E/FirebaseMessaging(26530):     at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:644)
E/FirebaseMessaging(26530):     at
com.google.android.gms.common.util.concurrent.zza.run(com.google.android.gms:play-services-basement@@18.5.0:2)
E/FirebaseMessaging(26530):     at java.lang.Thread.run(Thread.java:1012)
E/FirebaseMessaging(26530): Caused by: com.google.firebase.installations.FirebaseInstallationsException: Firebase Installations Service
is unavailable. Please try again later.
E/FirebaseMessaging(26530):     at com.google.firebase.installations.remote.FirebaseInstallationServiceClient.createFirebaseInstallation(FirebaseInstallationServiceClient.java:154)
E/FirebaseMessaging(26530):     at
com.google.firebase.installations.FirebaseInstallations.registerFidWithServer(FirebaseInstallations.java:533)
E/FirebaseMessaging(26530):     at
com.google.firebase.installations.FirebaseInstallations.doNetworkCallIfNecessary(FirebaseInstallations.java:387)
E/FirebaseMessaging(26530):     at com.google.firebase.installations.FirebaseInstallations.lambda$doRegistrationOrRefresh$3$com-google-firebase-installations-FirebaseInstallations(FirebaseInstallations.java:372)
E/FirebaseMessaging(26530):     at
com.google.firebase.installations.FirebaseInstallations$$ExternalSyntheticLambda1.run(D8$$SyntheticClass:0)
E/FirebaseMessaging(26530):     at
com.google.firebase.concurrent.SequentialExecutor$1.run(SequentialExecutor.java:117)
E/FirebaseMessaging(26530):     at com.google.firebase.concurrent.SequentialExecutor$QueueWorker.workOnQueue(SequentialExecutor.java:229)
E/FirebaseMessaging(26530):     at com.google.firebase.concurrent.SequentialExecutor$QueueWorker.run(SequentialExecutor.java:174)
E/FirebaseMessaging(26530):     at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1145)
E/FirebaseMessaging(26530):     at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:644)
E/FirebaseMessaging(26530):     at com.google.firebase.concurrent.CustomThreadFactory.lambda$newThread$0$com-google-firebase-concurrent-CustomThreadFactory(CustomThreadFactory.java:47)
E/FirebaseMessaging(26530):     at com.google.firebase.concurrent.CustomThreadFactory$$ExternalSyntheticLambda0.run(D8$$SyntheticClass:0)
E/FirebaseMessaging(26530):     ... 1 more
I/flutter (26530): FCM token unavailable: unknown
I/flutter (26530): DeviceService initialized successfully
I/flutter (26530): Battery monitoring stopped

--- DataCollector : Conflit d'isolates ---
I/flutter (26530): [DataCollector] Collection lease unavailable for background_isolate  [×2]
I/flutter (26530): [DataCollector] startCollectors() skipped: another isolate owns collection  [×2]
I/flutter (26530): Background isolate: another isolate owns collection; keeping service alive  [×2]
I/flutter (26530): Main isolate received: service_started

--- ═══════════════════════════════════════════════════════════════
     COLLECTE DES APPELS — Bootstrap mais JAMAIS SYNCHRONISÉ
     ═══════════════════════════════════════════════════════════════ ---

I/flutter (26530): [Calls] Bootstrap completed: 51 historical calls captured.
I/flutter (26530): Queued calls data for sync with priority 2  [×51 — une par appel]
I/flutter (26530): Calls: Processed 51 items
I/flutter (26530): Calls periodic check complete: 51 new calls

--- Configuration d'affichage ---
I/flutter (26530): Display mode changed to NORMAL
I/flutter (26530): Notification mode changed to VISIBLE
I/flutter (26530): Auto start enabled
I/flutter (26530): Initial configuration saved

--- Application terminée (aucune sync des appels n'a eu lieu) ---
Application finished.
```

---

## Observations critiques pour l'analyse des problèmes d'accès/affichage des données

### 1. 🔴 Appels (Calls) — JAMAIS synchronisés
- **51 appels historiques** capturés lors du bootstrap (`[Calls] Bootstrap completed: 51 historical calls captured`)
- **51 items mis en file d'attente** (`Queued calls data for sync with priority 2` × 51)
- **Aucun `REQUEST[POST]` pour les appels** n'apparaît dans les logs
- L'application s'est terminée avant que la synchronisation des appels ne soit déclenchée
- **Cause probable** : L'application a été relancée (re-démarrage visible dans les logs) après le bootstrap des appels mais avant la synchronisation, et le re-démarrage a réinitialisé l'état sans reprendre la sync des appels en attente

### 2. 🟡 Permissions Localisation = `denied`
- Le PATCH de statut appareil indique clairement : `permissions_status: {location: denied, ...}`
- La configuration de collecte indique `location: {enabled: true, interval_seconds: 900, accuracy: BALANCED}`
- **Contradiction** : la collecte est activée côté config mais la permission est refusée côté système
- Les 6 items de localisation ont été envoyés via l'endpoint `/api/v1/data/collect/` (non-bulk) au lieu du bulk endpoint, ce qui est une différence de comportement notable

### 3. 🟡 Format SMS incohérent entre les deux batches du bulk sync
- **Batch 1** (Phase 1) : utilise `conversation_id: 1` (pas de `collected_at`)
  - Exemple : `{message_type: SMS, direction: INCOMING, sender: MTN, ..., conversation_id: 1, has_attachment: false}`
- **Batch 2** (Phase 2) : utilise `thread_id: 1` + `collected_at: 2026-06-12T05:26:00.826054`
  - Exemple : `{message_type: SMS, direction: INCOMING, sender: MTN, ..., thread_id: 1, has_attachment: false, collected_at: 2026-06-12T05:26:00.826054}`
- **Impact** : le backend reçoit des SMS avec des champs différents selon le batch, ce qui peut causer des problèmes de mapping côté application surveillante

### 4. 🔴 Médias — Médias collectés mais thumbnails exclus
- **30 images + 2 vidéos + 13 audio** = 45 items media_metadata synchronisés
- La config indique `include_thumbnails: false`
- Le endpoint `/api/v1/data/collect/bulk/` renvoie `data_type: media` (pas `media_metadata`)
- **Aucun upload de fichiers médias** (images/vidéos/audio réels) n'est visible dans les logs — seules les métadonnées sont envoyées

### 5. 🟡 FCM Token — Échec d'enregistrement
- `Failed to get FIS auth token` → `Firebase Installations Service is unavailable`
- Le device status confirme : `fcm_token_registered: false`
- **Impact** : pas de push notifications possibles depuis l'application surveillante

### 6. 🟢 SMS — Sync réussie
- 138 SMS synchronisés en 2 batches (100 + 38)
- Tous traités sans erreur (`error_count: 0`)

### 7. 🟢 Apps — Sync réussie
- 159 app_info + 20 app_usage synchronisés
- Tous traités sans erreur

### 8. 🟡 DataCollector — Conflit d'isolates
- Le background_isolate ne peut pas démarrer la collecte car le main_isolate en est propriétaire
- Message répété 2 fois : `[DataCollector] startCollectors() skipped: another isolate owns collection`
- **Impact potentiel** : si le main_isolate ne relance pas la collecte après re-démarrage, certaines données ne seront pas collectées

### 9. 🟢 App usage — Bootstrap complet
- 10 enregistrements d'usage d'apps traités lors du check périodique
- 159 apps installées collectées et stockées

### 10. 🟡 Location — Sync via endpoint non-bulk
- 6 items de localisation envoyés via `/api/v1/data/collect/` (endpoint unitaire) au lieu de `/api/v1/data/collect/bulk/`
- Les données montrent des positions identiques avec des timestamps très proches (05:26:07.277 à 05:26:07.339)
- Deux formats de données mélangés dans le même batch (certains avec `bearing`, d'autres avec `heading`; certains avec `activity_type: null`, d'autres avec `activity_type: UNKNOWN`)

---

## Résumé des données collectées vs synchronisées

| Type de données | Collecté | Synchronisé | Statut |
|---|---|---|---|
| SMS | 138 | 138 | ✅ OK |
| App info | 159 | 159 | ✅ OK |
| App usage | 20 | 20 | ✅ OK |
| Media metadata | 45 (30 img + 2 vid + 13 audio) | 45 | ✅ Métadonnées OK, fichiers NON uploadés |
| Location | 6 | 6 | ⚠️ Permission denied, endpoint non-bulk |
| **Calls** | **51** | **0** | **🔴 JAMAIS SYNCHRONISÉ** |