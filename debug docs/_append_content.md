-07T03:44:07.907732}, {message_type: SMS, ... (truncated) }]}]}
I/flutter (21089): RESPONSE[200] => http://192.168.1.127:8000/api/v1/data/collect/bulk/
I/flutter (21089): DATA => {success: true, partial_success: false, device_id: 9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721, processed_batches: 4, successful_batches: 4, failed_batches: 0, results: [{data_type: messages, result: {success: true, processed_count: 20, error_count: 0, batch_id: 21ef8732-3055-4463-90c4-ed62d66f1f44, device_id: 9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721, data_type: messages, item_errors: []}}, {data_type: app_info, result: {success: true, processed_count: 58, error_count: 0, batch_id: 4fa9754f-989c-4eda-a712-63916bddc09f, device_id: 9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721, data_type: app_info, item_errors: []}}, {data_type: app_usage, result: {success: true, processed_count: 24, error_count: 0, batch_id: d98db6c0-0021-45d0-add6-98ae5294b73f, device_id: 9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721, data_type: app_usage, item_errors: []}}, {data_type: media, result: {success: true, processed_count: 45, error_count: 0, batch_id: 127258bc-1e8d-4d0b-bdb3-d2f2ae214698, device_id: 9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721, data_type: me... (response body tronqué dans les logs bruts)}]}
```

### Synthèse du sync
```
I/flutter (21089): Sync status updated: completed
I/flutter (21089): Sync completed: 120 sms items
I/flutter (21089): Sync completed: 158 app_info items
I/flutter (21089): Sync completed: 24 app_usage items
I/flutter (21089): Sync completed: 45 media_metadata items
I/flutter (21089): Marked 347 items as synced
I/flutter (21089): Optimized bulk sync completed: 4 types, 347 items
```

> **Incohérence à investiguer** :
> - 1er POST `processed_count: 100 sms / 100 app_info` puis 2e POST `processed_count: 20 sms / 58 app_info / 24 app_usage / 45 media`
> - Totaux reportés localement : `120 sms` (= 100+20 ✓) / `158 app_info` (= 100+58 ✓) / `24 app_usage` / `45 media` — cohérent côté monitored_app.
> - Mais le backend ne confirme JAMAIS explicitement un total cumulé pour ces 4 types. Si l'app surveillante interroge un endpoint d'agrégat (ex. `GET /api/v1/devices/{id}/summary/` ou similaire), un décalage entre "347 items synced" et la base de données est possible.

> **Côté `calls` — pas de batch bulk détecté dans les logs** : les 48 appels capturés sont mis en queue (`Queued calls data for sync with priority 2` x48, supprimés) mais **AUCUN** `POST /api/v1/data/collect/bulk/` ne contient `data_type: calls` dans cette exécution. Si l'app surveillante n'affiche pas la liste des appels, c'est un **suspect n°1** : la file d'attente locale des calls n'est pas flushée vers le backend pendant cette session.

---

## 10. WebSocket events reçus (post-sync)
```
I/flutter (21089): WebSocket: Received message type: device_status
I/flutter (21089): WebSocket: Received message type: device_status
I/flutter (21089): WebSocket: Received message type: device_status
I/flutter (21089): WebSocket: Received message type: device_status
```

> ~5 occurrences identiques pendant la fin d'exécution. **Aucun** message de type `data_request`, `config_update`, `display_mode_change`, `sync_command`, `media_request`, `location_request`, etc. n'est reçu pendant cette session. Le WebSocket est utilisé en **monodirectionnel sortant** (heartbeat + device_status en push) — aucune commande entrante n'est journalisée.

> **🔴 Hypothèse forte** : Si l'app surveillante déclenche un re-fetch de données (ex. onglet "Medias" ouvert), la commande devrait arriver via WebSocket. Le fait qu'aucun `WebSocket: Received message type: ...` autre que `device_status` n'apparaisse suggère soit que :
> - l'app surveillante n'envoie pas de commande temps réel au monitored_app (mode polling uniquement),
> - ou que le canal de commande est différent (HTTP REST direct).

---

## 11. Configuration initiale sauvegardée localement
```
I/flutter (21089): Display mode changed to NORMAL
I/flutter (21089): Notification mode changed to VISIBLE
I/flutter (21089): Auto start enabled
I/flutter (21089): Initial configuration saved
I/flutter (21089): Battery monitoring stopped
I/flutter (21089): [DataCollector] startCollectors() skipped: collectors already running for main_isolate
```

---

## 12. Démarrage du background isolate (Flutter Engine count = 2)

> ⚠️ **Le Background service started ré-initialise toute la stack**. Cela correspond à un second démarrage de l''app en arrière-plan (foreground service détaché). C''est ici que la **race condition entre isolates** documentée dans MONITORED_APP_ISSUE_DUAL_ISOLATE_COLLECTOR_RACE_20260512.md peut se manifester.

`
W/HwCust  (21089): CUST VERSION = false, use class = class android.app.HwCustNotificationImpl
W/FlutterJNI(21089): FlutterJNI.loadLibrary called more than once
W/FlutterJNI(21089): FlutterJNI.prefetchDefaultFontManager called more than once
I/ResourceExtractor(21089): Found extracted resources res_timestamp-1-1780798827289
W/FlutterJNI(21089): FlutterJNI.init called more than once
I/flutter (21089):
[IMPORTANT:flutter/shell/platform/android/android_context_gl_impeller.cc(94)] Using the Impeller rendering backend (OpenGLES).
D/FLTFireContextHolder(21089): received application context.
I/flutter (21089): Background service started
I/flutter (21089): Enhanced battery status reported: 97%, charging: false, health: good
I/flutter (21089): Switching to performance mode: maximum
I/flutter (21089): Applied maximum performance mode
I/flutter (21089): WebSocket: Received message type: device_status
W/FlutterWebRTCPlugin(21089): audioFocusChangeListener [Earpiece(name=Earpiece)] Earpiece(name=Earpiece)
W/FlutterWebRTCPlugin(21089): audioFocusChangeListener [Speakerphone(name=Speakerphone), Earpiece(name=Earpiece)] Speakerphone(name=Speakerphone)
I/flutter (21089): Enhanced battery status reported: 97%, charging: true, health: good
`

### Ré-init AppConfig & services (background isolate)
`
I/flutter (21089): AppConfig initialized: env=dev, api=http://192.168.1.127:8000/api/v1, displayMode=NORMAL
I/flutter (21089): WebSocket: Received message type: device_status
I/flutter (21089): Database initialized with encryption
I/flutter (21089): BatteryMonitorService initialized
I/flutter (21089): SyncStatusMonitor initialized
I/flutter (21089): Enhanced battery monitoring started
I/flutter (21089): Sync status updated: completed
`

### GET /api/v1/data/collection-config/ (2ème exécution)
`
I/flutter (21089): REQUEST[GET] => http://192.168.1.127:8000/api/v1/data/collection-config/?device_id=9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721
I/flutter (21089): DATA => null
I/flutter (21089): RESPONSE[200] => http://192.168.1.127:8000/api/v1/data/collection-config/?device_id=9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721
I/flutter (21089): DATA => {location: {enabled: true, interval_seconds: 900, accuracy: BALANCED}, messages: {enabled: true, types: [SMS, MMS, WHATSAPP, TELEGRAM, MESSENGER], include_content: true}, calls: {enabled: true, record_calls: false}, app_usage: {enabled: true, interval_minutes: 30}, media: {enabled: true, scan_interval_hours: 24, include_thumbnails: false}}
I/flutter (21089): Collection configuration loaded: (location, messages, calls, app_usage, media)
`
