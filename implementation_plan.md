# Implementation Plan

[Overview]
Improve app label resolution in the monitored_app Android native layer to return the exact launcher-label (home screen name) instead of the generic application-label, especially for apps with limited package visibility on Android 11+.

The issue document (`debug docs/MONITORED_APP_ISSUE_APP_LABELS_LAUNCHER_20260614.md`) describes a case where certain apps on Android 11+ (Honor GFY-LX2, Android 14) return `packageName` as the label because `getApplicationLabel()` either returns the wrong label or fails with `NameNotFoundException`. The fix requires two changes in the Android native layer: (1) add `QUERY_ALL_PACKAGES` permission to see all installed packages, and (2) replace the label resolution with a 3-tier strategy that first tries the launcher-activity label, then the application label, then falls back to `packageName`. A secondary fix is needed for the `category` field at line 97 which calls `getApplicationInfo()` without try-catch, risking a crash on Android 11+ for invisible packages. The same launcher-label improvement should be applied to `getAppUsage()` (lines 157-159) for consistency — though `getAppUsage()` already has a try-catch wrapper, the label resolution should also use the launcher-first approach. No Dart-side or backend changes are required; the app name flows verbatim through the existing Dart collector and sync pipeline.

[Types]
No new types, interfaces, enums, or data structures are being introduced. The fix is purely functional — adding one private helper method and updating three existing expression lines.

- `private fun resolveAppLabel(packageName: String): String` — new method returning the best available label
  - Return type: `String` (never null)
  - Logic: try launcher-label → try application-label → fallback packageName
  - Robust: catches `NameNotFoundException` and generic `Exception`

[Files]
Two existing files will be modified; no files created, deleted, or moved.

- **`android/app/src/main/AndroidManifest.xml`** — Add `QUERY_ALL_PACKAGES` permission after the existing media permissions (line 40)
  - Change: Insert `<uses-permission android:name="android.permission.QUERY_ALL_PACKAGES" tools:ignore="QueryAllPackagesPermission" />`
- **`android/app/src/main/kotlin/com/xpsafeconnect/monitored_app/AppsCollectorPlugin.kt`** — Three changes:
  1. Add `private fun resolveAppLabel(packageName: String): String` method (anywhere in class body, before `getInstalledApps()`)
  2. Replace line 90: use `resolveAppLabel(packageInfo.packageName)` instead of the current inline ternary
  3. Fix line 96-97 category resolution: wrap `getApplicationInfo()` in try-catch to prevent crash on Android 11+
  4. Replace lines 157-159 in `getAppUsage()`: use `resolveAppLabel(packageName)` instead of `getApplicationLabel()`

[Functions]
- **NEW**: `resolveAppLabel(packageName: String): String` in `AppsCollectorPlugin.kt`
  - Signature: `private fun resolveAppLabel(packageName: String): String`
  - Purpose: Resolve the best label for a package using 3-tier fallback
  - Implementation:
    1. Query launcher activities via `Intent(ACTION_MAIN).addCategory(CATEGORY_LAUNCHER).setPackage(packageName)` → if found, `loadLabel(packageManager).toString()`
    2. If no launcher label, get `applicationInfo` and call `getApplicationLabel(appInfo).toString()`
    3. Fallback: return `packageName`
  - Error handling: catch `NameNotFoundException` (invisible package) and generic `Exception`, log warning, return `packageName`

- **MODIFIED**: `getInstalledApps()` line 90 in `AppsCollectorPlugin.kt`
  - Change: `"app_name" to resolveAppLabel(packageInfo.packageName)` replaces the inline ternary
  - Semantics: Same 3-tier resolution, covers the case where `appInfoObj` is null

- **MODIFIED**: `getInstalledApps()` lines 96-97 in `AppsCollectorPlugin.kt`
  - Change: Wrap `packageManager.getApplicationInfo(packageInfo.packageName, 0).category.toString()` in a try-catch for `NameNotFoundException`
  - Reason: On Android 11+, `getApplicationInfo()` can throw for packages invisible without `QUERY_ALL_PACKAGES`
  - Fallback: `""` (empty string)

- **MODIFIED**: `getAppUsage()` lines 157-159 in `AppsCollectorPlugin.kt`
  - Change: `val appName = resolveAppLabel(packageName)` replaces `getApplicationLabel(appInfo).toString()`
  - Note: This also lets us remove the separate `try` around `getApplicationInfo` at line 158 since `resolveAppLabel` already catches it — but we keep the outer try-catch for safety

[Classes]
- **MODIFIED**: `AppsCollectorPlugin` (Kotlin class in `AppsCollectorPlugin.kt`)
  - Change: Add `resolveAppLabel()` method
  - Change: Update `getInstalledApps()` — line 90 label resolution + line 97 category resolution
  - Change: Update `getAppUsage()` — lines 157-159 label resolution
  - No inheritance changes, no interface changes

[Dependencies]
No new dependencies. The `PackageManager`, `Intent`, and related classes are already imported:
- `android.content.Intent` (already imported at line 7)
- `android.content.pm.PackageManager` (already imported at line 9)
- No additional imports needed

[Testing]
- No automated tests are being added or modified (the file is native Kotlin with no existing test harness)
- Validation strategy:
  1. Build: `flutter build apk --debug` must succeed with zero warnings
  2. Deploy to Android 14 device (Honor GFY-LX2)
  3. Open monitored_app → trigger apps sync
  4. Verify via backend `GET /api/v1/app_info/` that previously invisible apps now show correct launcher labels
  5. Verify via monitor_app Apps tab that all app names match the home screen

[Implementation Order]
Implementation must proceed in this exact order to avoid compilation errors:

1. **AndroidManifest.xml**: Add `QUERY_ALL_PACKAGES` permission
2. **AppsCollectorPlugin.kt**: Add `resolveAppLabel()` private method
3. **AppsCollectorPlugin.kt**: Replace line 90 `app_name` resolution
4. **AppsCollectorPlugin.kt**: Fix lines 96-97 category resolution with try-catch
5. **AppsCollectorPlugin.kt**: Replace lines 157-159 label resolution in `getAppUsage()`
6. **Verify**: Run `flutter analyze` and `flutter build apk --debug` to confirm zero warnings
7. **Final**: Review all changed files for consistency and completeness