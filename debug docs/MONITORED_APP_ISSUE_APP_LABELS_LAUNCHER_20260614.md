# Monitored App Issue — Labels d'apps : passer au libellé launcher exact (Android 11+)

**Issue Type**: MONITORED_APP_ISSUE_ENHANCEMENT
**Date Created**: 2026-06-14
**Status**: 🟡 Partiel — fix monitor_app appliqué (noms frontend corrects pour les apps avec label résolu) ; raffinement monitored_app optionnel pour les cas edge
**Priorité**: Basse — amélioration de qualité, non bloquant
**Cible**: `monitored_app` (Android, Honor GFY-LX2, Android 14)

---

## 1. Issue Summary

Sur Android 11+, certaines applications **dont le package est invisible** à la query courante retournent
`packageName` comme label au lieu de leur vrai nom (ex. une app dont le package n'est pas déclaré dans
`<queries>`). Le fix monitor_app corrige déjà l'heuristique frontend (le nom envoyé par le backend est
affiché verbatim). Ce document décrit la couche amont : garantir que `monitored_app` envoie toujours le
vrai libellé d'écran d'accueil même pour les apps peu visibles.

---

## 2. Situation actuelle (état de base 2026-06-14)

### monitor_app (fix déjà appliqué)

`_displayName()` ([apps_screen.dart:182-194](lib/features/apps/views/apps_screen.dart#L182-L194)) a été
corrigé : le libellé backend est affiché **verbatim** sauf repli réel (`appName == packageName` ou vide).
Plus de clause `contains('.')` qui mangeait les marques à point (« Booking.com », etc.).

### monitored_app (à améliorer)

`AppsCollectorPlugin.kt:90` — collecte actuelle :

```kotlin
"app_name" to (if (appInfoObj != null)
    packageManager.getApplicationLabel(appInfoObj).toString()
else packageInfo.packageName)  // repli = packageName
```

`getApplicationLabel` ne résout pas toujours le launcher-label sur Android 11+ :
- L'API renvoie le `android:label` de l'`<application>` (label global de l'apk).
- Le launcher-label est l'`android:label` de l'activité `ACTION_MAIN + CATEGORY_LAUNCHER`.
  Pour les apps comme WhatsApp (label app = « WhatsApp », launcher = « WhatsApp »), identique.
  Pour certaines apps système ou multi-activités, ils peuvent différer.
- De plus, Android 11+ **filtre la liste des packages** si le manifeste ne déclare pas `<queries>` ou
  `QUERY_ALL_PACKAGES` → `packageManager.getApplicationInfo()` peut échouer avec `NameNotFoundException`
  (ligne 168-170 de AppsCollectorPlugin.kt) → repli `packageName`.

---

## 3. Changements requis dans monitored_app

### 3.1 Autorisation QUERY_ALL_PACKAGES (AndroidManifest.xml)

Ajouter dans `android/app/src/main/AndroidManifest.xml` (après les autres `<uses-permission>`) :

```xml
<uses-permission android:name="android.permission.QUERY_ALL_PACKAGES"
    tools:ignore="QueryAllPackagesPermission" />
```

Cette permission est accordée automatiquement (pas de dialogue utilisateur) et permet à
`packageManager.getInstalledPackages()` et `getApplicationInfo()` de voir toutes les apps.

> **Note Google Play** : si l'app est distribuée sur le Play Store, QUERY_ALL_PACKAGES nécessite
> une justification. Pour un usage interne / APK direct, aucun problème.

### 3.2 Résolution du launcher-label (AppsCollectorPlugin.kt)

Remplacer la résolution du label (`AppsCollectorPlugin.kt`, autour de la ligne 90) par une méthode
qui essaie d'abord le launcher-label, puis le label application, puis le packageName :

```kotlin
private fun resolveAppLabel(packageName: String): String {
    return try {
        // Essai 1 : label de l'activité launcher (vrai nom de l'écran d'accueil)
        val launcherIntent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_LAUNCHER)
            setPackage(packageName)
        }
        val launcherActivities = packageManager.queryIntentActivities(launcherIntent, 0)
        val launcherLabel = launcherActivities
            .firstOrNull()
            ?.loadLabel(packageManager)
            ?.toString()
            ?.takeIf { it.isNotBlank() && it != packageName }

        if (launcherLabel != null) return launcherLabel

        // Essai 2 : label global de l'application
        val appInfo = packageManager.getApplicationInfo(packageName, 0)
        val appLabel = packageManager.getApplicationLabel(appInfo).toString()
            .takeIf { it.isNotBlank() && it != packageName }

        appLabel ?: packageName  // repli final

    } catch (e: PackageManager.NameNotFoundException) {
        packageName  // app invisible (repli)
    } catch (e: Exception) {
        Log.w(TAG, "resolveAppLabel($packageName): ${e.message}")
        packageName
    }
}
```

Puis remplacer la ligne 90 :
```kotlin
// Avant :
"app_name" to (if (appInfoObj != null) packageManager.getApplicationLabel(appInfoObj).toString() else packageInfo.packageName)

// Après :
"app_name" to resolveAppLabel(packageInfo.packageName)
```

---

## 4. Impact attendu

| Cas | Avant | Après |
|---|---|---|
| App connue (WhatsApp, Chrome, YouTube) | ✅ Déjà correct | ✅ Identique |
| App à marque avec point (Booking.com) | ✅ Déjà correct côté backend | ✅ Identique |
| App système / peu visible Android 11+ | ⚠️ Peut remonter `packageName` en repli | ✅ Launcher-label résolu si visible |
| App sans launcher (service pur) | `packageName` | `packageName` (repli normal) |

---

## 5. Verification

1. Déployer monitored_app rebuilt.
2. Déclencher une sync apps (ouvrir l'app ou attendre le cycle).
3. Backend : `GET /api/v1/app_info/?device=9989a82e…` — vérifier `app_name` des apps anciennement en repli.
4. monitor_app → onglet Apps : tous les noms correspondent à l'écran d'accueil du Honor.

---

## Cross-References

- Fix monitor_app `_displayName()` déjà appliqué — [apps_screen.dart:182-194](lib/features/apps/views/apps_screen.dart#L182-L194).
- `MONITORED_APP_ISSUE_CALLS_EMPTY_DIAGNOSTIC_20260614.md` — même device, même session.

---

**Frontend Team Contact**: Eric Vekout — **Date**: 2026-06-14
