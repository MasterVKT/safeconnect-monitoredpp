# Monitored App Issue — Nom et modèle de l'appareil non mis à jour après le jumelage

**Target Application**: MONITORED_APP (flutter_apps/monitored_app)
**Detected From**: monitor_app (flutter_apps/monitor_app)
**Issue Type**: MONITORED_APP_ISSUE_DEVICE_REGISTRATION
**Date Created**: 2026-05-26
**Status**: 🔴 Blocked — implémentation monitored_app requise (+ correctif backend complémentaire)
**Priority**: Medium (l'appareil est visible dans monitor_app mais avec un nom trompeur qui donne l'impression que le jumelage est encore en cours)
**Data / Feature Affected**: Dashboard monitor_app — affichage de la liste des appareils surveillés

---

## Related Issue File

**Cross-dependency** : lié à `BACKEND_ISSUE_DEVICE_LIST_MISSING_MONITORED_BY_20260526.md`.
**Ordre recommandé** : monitored_app en premier (envoie le vrai `device_name` post-pairing), backend en second (expose `is_monitored` dans la réponse LIST et accepte le PATCH de `device_name`).

---

## 1. Issue Summary

Le backend initialise `device_name = "Mon appareil (en cours de jumelage)"` et `device_model = "A configurer"` lors de la création du device (avant le jumelage). Ces valeurs placeholder ne sont jamais remplacées par le vrai nom et modèle de l'appareil Android après que monitored_app complète le jumelage. Résultat : monitor_app affiche ces libellés de façon permanente, donnant à l'utilisateur l'impression que le jumelage n'a pas abouti.

---

## 2. Context & When It Occurred

**Date** : 2026-05-26
**Écran monitor_app affecté** : Dashboard → section "Appareils surveillés" (`lib/features/home/home_screen.dart:_buildDeviceCard`) et liste des appareils (`lib/features/devices/views/devices_screen.dart`).
**Action utilisateur** : Ouvrir monitor_app après un jumelage réussi.
**Environnement** : Dev. Jumelage confirmé (`isMonitored = true`, device visible dans la liste).

**Ce qui s'affiche** :
- Nom : `"Mon appareil (en cours de jumelage)"`
- Modèle : `"A configurer"`

**Ce qui devrait s'afficher** :
- Nom : `"[Nom Android de l'appareil]"` (ex : "Pixel 7" ou nom personnalisé)
- Modèle : `"[Modèle réel]"` (ex : "Samsung Galaxy A52")

---

## 3. Expected Behavior (Per Specifications)

D'après les spécifications d'intégration :

1. À l'issue du jumelage, monitored_app s'authentifie et obtient l'UUID backend de son device.
2. monitored_app envoie `PATCH /api/v1/devices/devices/{device_id}/` avec le nom réel et le modèle réel de l'appareil Android.
3. monitor_app affiche dans le dashboard le nom et modèle réels de l'appareil (pas les valeurs placeholder créées pre-pairing).

---

## 4. Actual Behavior (Observed)

### 4.1 Valeurs dans le backend (GET /api/v1/devices/devices/{id}/)

```json
{
  "id": "<uuid>",
  "device_name": "Mon appareil (en cours de jumelage)",
  "device_model": "A configurer",
  "is_monitored": true,
  "monitored_by": [{"id": "...", "...": "..."}]
}
```

### 4.2 Affichage dans monitor_app

`DeviceModel.fromJson` (`lib/core/models/api_models.dart:225-232`) lit :
```dart
deviceName: (json['deviceName'] ?? json['device_name'] ?? json['name'] ?? '') as String,
deviceModel: (json['deviceModel'] ?? json['device_model'] ?? json['model'] ?? '') as String,
```

`_convertToDevice` (`lib/core/services/device_service_new.dart:224`) :
```dart
Device(
  name: apiDevice.deviceName,   // "Mon appareil (en cours de jumelage)"
  model: apiDevice.deviceModel, // "A configurer"
  ...
)
```

Le dashboard affiche ces valeurs brutes telles quelles — aucun fallback.

---

## 5. Root Cause in monitored_app Code

### 5.1 `updateDeviceStatus()` n'envoie pas `device_name`

`lib/core/services/device_service.dart:updateDeviceStatus()` (ligne ~165) envoie un PATCH avec :
```dart
final statusData = {
  'battery_level': batteryLevel,
  'is_charging': isCharging,
  'is_online': networkStatus != NetworkStatus.offline,
  'last_sync': DateTime.now().toIso8601String(),
  'storage_available': await _getAvailableStorage(),
  'network_type': _getNetworkTypeName(networkStatus),
  'location_enabled': await _isLocationEnabled(),
  'permissions_status': permissionsStatus,
  'app_version': packageInfo.version,
  'os_version': await DeviceUtils.getOSVersion(),
  'device_model': await DeviceUtils.getDeviceModel(),
  // 'device_name' : ABSENT — jamais envoyé
};
```

`device_model` est bien envoyé mais le backend ne l'accepte peut-être pas en PATCH (voir issue backend liée). `device_name` n'est **jamais** envoyé.

### 5.2 Pas de registration post-pairing

Il n'y a aucun appel dédié post-pairing pour mettre à jour le nom/modèle de l'appareil. Le flux de pairing (`lib/features/auth/views/pairing_screen.dart`) ou `setup_complete_screen.dart` ne déclenche pas de PATCH de `device_name`.

---

## 6. Required monitored_app Changes

### 6.1 Ajouter `device_name` dans `updateDeviceStatus()`

**Fichier** : `lib/core/services/device_service.dart`

**Action** : Ajouter `device_name` dans `statusData` :

```dart
final statusData = {
  'battery_level': batteryLevel,
  'is_charging': isCharging,
  'is_online': networkStatus != NetworkStatus.offline,
  'last_sync': DateTime.now().toIso8601String(),
  'storage_available': await _getAvailableStorage(),
  'network_type': _getNetworkTypeName(networkStatus),
  'location_enabled': await _isLocationEnabled(),
  'permissions_status': permissionsStatus,
  'app_version': packageInfo.version,
  'os_version': await DeviceUtils.getOSVersion(),
  'device_model': await DeviceUtils.getDeviceModel(),
  'device_name': await DeviceUtils.getDeviceName(),  // ← AJOUT
};
```

`DeviceUtils.getDeviceName()` doit retourner le nom Android de l'appareil (depuis `device_info_plus` : `AndroidDeviceInfo.model` ou le nom personnalisé de l'utilisateur si disponible).

**Méthode à ajouter dans `DeviceUtils`** (`lib/core/utils/device_utils.dart`) :

```dart
static Future<String> getDeviceName() async {
  try {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      // Priorité : nom marketing → modèle
      return androidInfo.device.isNotEmpty
          ? '${androidInfo.brand} ${androidInfo.model}'
          : androidInfo.model;
    }
    return 'Unknown Device';
  } catch (e) {
    debugPrint('[DeviceUtils] Error getting device name: $e');
    return 'Unknown Device';
  }
}
```

### 6.2 Envoyer le nom à l'issue du pairing (première fois)

**Fichier** : `lib/features/auth/views/setup_complete_screen.dart` ou `lib/core/services/device_service.dart:initialize()`

**Action** : Déclencher un `updateDeviceStatus()` immédiatement après le pairing réussi (ou s'assurer que le premier `initialize()` le fait, ce qui est déjà le cas).

La premier appel à `updateDeviceStatus()` dans `initialize()` est suffisant **si** `device_name` est ajouté au payload (voir 6.1).

---

## 7. Temporary Workaround (monitor_app)

**Status** : ⚠️ Aucun workaround parfait — affichage des valeurs placeholder.

**Mitigation possible** (non implémentée) : dans `devices_viewmodel.dart:_isDisplayableDevice()`, on pourrait filtrer les devices avec `name.contains("en cours de jumelage")` comme condition supplémentaire. Mais cette approche est fragile (si le backend traduit le message) et a été **délibérément retirée** dans un fix précédent (commit non daté) pour éviter de masquer les appareils fraîchement appairés. Elle n'est donc **pas recommandée**.

---

## 8. Verification Steps

### Vérification monitored_app

```bash
cd flutter_apps/monitored_app
flutter analyze
```

Sur device physique après correctif :
1. Installer monitored_app → compléter le jumelage.
2. Attendre la première `updateDeviceStatus()` (~5 min ou au démarrage).
3. `GET /api/v1/devices/devices/{id}/` depuis le backend : vérifier que `device_name` et `device_model` ne sont plus les valeurs placeholder.

### Vérification end-to-end (monitor_app)

1. monitor_app → Dashboard : l'appareil surveillé affiche son nom réel (ex : "Samsung Galaxy A52") et non "Mon appareil (en cours de jumelage)".
2. monitor_app → Liste des appareils : même vérification.

---

**Frontend Team Contact** : Eric Vekout
**Backend Team Notified** : Voir `BACKEND_ISSUE_DEVICE_LIST_MISSING_MONITORED_BY_20260526.md`
