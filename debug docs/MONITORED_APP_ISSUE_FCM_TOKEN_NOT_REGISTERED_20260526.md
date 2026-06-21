# Monitored App Issue — Token FCM jamais enregistré sur le backend

**Target Application**: MONITORED_APP (flutter_apps/monitored_app)
**Detected From**: monitor_app (flutter_apps/monitor_app)
**Issue Type**: MONITORED_APP_ISSUE_FCM
**Date Created**: 2026-05-26
**Status**: 🔴 Blocked — implémentation monitored_app requise
**Priority**: Medium (le trigger-sync manuel échoue ; la synchronisation automatique périodique continue de fonctionner)
**Data / Feature Affected**: synchronisation manuelle des messages via FCM (`POST /api/v1/messages/trigger-sync/`)

---

## Related Issue File

**Cross-dependency** : lié à `BACKEND_ISSUE_TRIGGER_SYNC_FCM_NO_DEGRADATION_20260526.md`.
Les deux correctifs doivent être appliqués. **Ordre recommandé : monitored_app d'abord** (enregistre le vrai token FCM, résout le problème racine), **backend ensuite** (dégrade gracieusement quand le token est absent — robustesse même sur émulateur).

---

## 1. Issue Summary

monitored_app n'enregistre jamais son token FCM sur le backend. Résultat : `POST /api/v1/messages/trigger-sync/` retourne `400 "L'appareil n'a pas de jeton FCM configuré"`. Le trigger-sync est la seule voie de synchronisation immédiate des messages depuis monitor_app.

---

## 2. Context & When It Occurred

**Date** : 2026-05-26
**Écran monitor_app affecté** : Écran Messages (`lib/features/messages/views/`) → bouton de synchronisation manuelle.
**Action utilisateur** : Ouvrir l'écran Messages → appuyer sur Sync (ou `refreshConversations()`).
**Environnement** : émulateur Android (Firebase Installations Service indisponible sur émulateur → `FirebaseInstallations.getInstance().getId()` échoue silencieusement → `fcm_token = null` dans le backend).

**Fréquence** :
- 100 % reproductible sur émulateur (Firebase indisponible).
- Potentiellement reproductible sur device physique si le token n'est pas enregistré lors du pairing ou du premier démarrage.

---

## 3. Expected Behavior (Per Specifications)

D'après `docs/API-Endpoints-Application-Surveillee.md` (section WebSocket / FCM registration) :

1. À l'initialisation (pairing ou premier boot post-pairing), monitored_app obtient son token FCM depuis Firebase.
2. monitored_app envoie le token au backend via `PATCH /api/v1/devices/devices/{device_id}/` avec le champ `fcm_token`.
3. Quand monitor_app demande `POST /api/v1/messages/trigger-sync/`, le backend envoie une notification push FCM à l'appareil surveillé → monitored_app déclenche une synchronisation immédiate.
4. Résultat attendu : nouvelles conversations/messages apparaissent dans monitor_app en < 30 s.

---

## 4. Actual Behavior (Observed)

### 4.1 Backend response
```
POST /api/v1/messages/trigger-sync/
Body: {"device_id": "<uuid>"}

HTTP 400 Bad Request
{"error": "L'appareil n'a pas de jeton FCM configuré."}
```

### 4.2 Logs monitored_app (émulateur)
```
W/Firebase: Firebase Installations Service is unavailable.
D/FlutterFirebasePlugin: FirebaseInstallations.getId() failed: ...
[DeviceService] fcm_token not obtained, skipping registration
```

### 4.3 Comportement monitor_app (avant correctif UX)
`refreshConversations()` → `triggerMessageSync()` lève une `DioException` → `ConversationsState.error(e.toString())` → affichage du stack trace brut à l'utilisateur.

*(Correctif UX déjà appliqué dans `messages_viewmodel.dart` commit `771200e` : l'erreur 400 ne provoque plus d'état d'erreur, mais le trigger-sync reste sans effet.)*

---

## 5. Root Cause in monitored_app Code

### 5.1 Absence d'envoi du token FCM

`lib/core/services/device_service.dart` — `updateDeviceStatus()` (ligne ~165) envoie un `PATCH /devices/devices/{device_id}/` avec les champs :
```dart
'battery_level', 'is_charging', 'is_online', 'last_sync',
'storage_available', 'network_type', 'location_enabled',
'permissions_status', 'app_version', 'os_version', 'device_model'
```

**`fcm_token` est absent de ce PATCH.** Il n'est jamais envoyé au backend.

### 5.2 Pas d'initialisation FCM dans le flux de démarrage

`lib/core/services/device_service.dart` — `initialize()` :
```dart
Future<void> initialize() async {
  if (_isInitialized) return;
  // ...
  await loadCollectionConfiguration();
  // Start periodic status updates
  _statusUpdateTimer = Timer.periodic(Duration(minutes: 5), (_) => updateDeviceStatus());
  await updateDeviceStatus();
  _isInitialized = true;
}
```

Aucun appel à `FirebaseMessaging.instance.getToken()` ou enregistrement FCM.

`lib/core/services/device_service.dart:updateFcmToken()` (note commentaire) :
```dart
Future<void> updateFcmToken(String token) async {
  // Note: Endpoint à ajouter dans SafeConnectApiService
  throw UnimplementedError('Update FCM token endpoint not yet implemented in API');
}
```

La méthode est définie mais **non implémentée** — et n'est pas appelée depuis le flux de démarrage.

---

## 6. Required monitored_app Changes

### 6.1 Obtenir le token FCM à l'initialisation

**Fichier** : `lib/core/services/device_service.dart`

**Action** : Dans `initialize()`, après `updateDeviceStatus()`, ajouter l'obtention et l'envoi du token FCM :

```dart
// Après updateDeviceStatus() dans initialize()
await _registerFcmToken();
```

**Nouvelle méthode** :

```dart
Future<void> _registerFcmToken() async {
  try {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) {
      debugPrint('[DeviceService] FCM token unavailable (emulator or Firebase not configured)');
      return;
    }
    final deviceId = await getServerDeviceId();
    if (deviceId == null) return;

    final response = await _apiClient.patch(
      '/devices/devices/$deviceId/',
      data: {'fcm_token': token},
    );

    if (response.statusCode == 200) {
      debugPrint('[DeviceService] FCM token registered successfully');
    } else {
      debugPrint('[DeviceService] FCM token registration failed: ${response.statusCode}');
    }
  } catch (e) {
    // Non-fatal: periodic sync continues to work without FCM
    debugPrint('[DeviceService] FCM token registration error: $e');
  }
}
```

### 6.2 Rafraîchir le token FCM quand il change

**Fichier** : `lib/main.dart` ou le point d'entrée de l'application.

**Action** : Écouter `FirebaseMessaging.instance.onTokenRefresh` pour renvoyer le nouveau token au backend :

```dart
FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
  final deviceService = locator<DeviceService>();
  await deviceService._registerFcmToken(); // ou méthode publique équivalente
});
```

### 6.3 Import requis

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
```

Vérifier que `firebase_messaging` est dans `pubspec.yaml` (déjà probablement présent pour les notifications).

---

## 7. Frontend Actions Already Completed

**Status** : ✅ Correctif UX monitor_app appliqué, backend encore bloquant.

**Fichier modifié** : `lib/features/messages/viewmodels/messages_viewmodel.dart`

**Ce qui a été changé** :
- Ajout de `import 'package:dio/dio.dart'`
- Dans `refreshConversations()` catch block : détection du 400 FCM (`e is DioException && e.response?.statusCode == 400`)
- Si 400 FCM : maintenir `isRefreshing: false` sans passer en `ConversationsState.error`
- Les erreurs non-400 continuent à propager `ConversationsState.error`

**Avant** : un 400 du backend crashait l'écran Messages avec un message d'erreur brut.
**Après** : la vue reste stable, `isRefreshing` passe à false, aucun message d'erreur intrusif.

**Validation** : `flutter analyze lib/features/messages/viewmodels/messages_viewmodel.dart` → `No issues found!`

**Dépendance backend restante** : tant que monitored_app n'enregistre pas le token FCM, le trigger-sync reste sans effet (400 ou éventuellement 200 si le backend dégrade gracieusement).

---

## 8. Verification Steps

### Vérification monitored_app (après correctif)

```bash
cd flutter_apps/monitored_app
flutter analyze
```

Ensuite, sur **device physique** (pas émulateur) :
1. Lancer monitored_app → laisser s'initialiser.
2. Vérifier dans les logs : `[DeviceService] FCM token registered successfully`.
3. Dans le backend admin ou via `GET /api/v1/devices/devices/{id}/`, vérifier que le champ `fcm_token` n'est plus `null`.

### Vérification end-to-end

1. monitor_app → Écran Messages → bouton Sync.
2. Vérifier que monitor_app reçoit `200 OK` du trigger-sync.
3. Sur le device physique : monitored_app déclenche une collecte et synchronise les derniers messages.
4. monitor_app affiche les conversations mises à jour en < 30 s.

---

**Frontend Team Contact** : Eric Vekout
**Backend Team Notified** : Voir `BACKEND_ISSUE_TRIGGER_SYNC_FCM_NO_DEGRADATION_20260526.md`
