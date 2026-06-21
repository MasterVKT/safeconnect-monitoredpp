# CLAUDE.md - Monitored App (XP SafeConnect)

**Version**: 2.0 (Complete & Optimized)
**Date**: 23/01/2026
**Project**: XP SafeConnect - Monitored App (Parental Control & Family Safety)

This file provides comprehensive guidance for AI agents working on the Monitored App. For detailed information on specific topics, refer to files in `.claude/rules/`.

---

## ⚠️ MANDATORY FIRST ACTION — EVERY REQUEST, NO EXCEPTIONS

**Before processing any request — including simple questions, analysis, explanations, or code tasks — you MUST:**

1. **Read [`skills/task-orchestrator/SKILL.md`](skills/task-orchestrator/SKILL.md)**
2. **Analyse the request intent** against the orchestrator's Selection Rules
3. **Invoke the matching skill(s)** in the order specified by the Multi-Skill Composition chain
4. **Only then** proceed with the actual work

This step is **non-negotiable**. It applies to every single request in this project, regardless of perceived simplicity. The orchestrator determines which skill(s) are optimal for the request; it is never acceptable to skip it and respond directly.

**If the task spans multiple intents**, follow the Multi-Skill Composition chain defined in the orchestrator:
`spec-audit` → `data-flow-trace` → primary fix skill → `backend-integration-reporting` → `cross-app-issue-authoring` → `quality-gates-flutter` → `session-handoff`

> Skipping this orchestration step is a critical compliance failure for this project.

---

## Quick Navigation

1. [Project Overview](#1-project-overview)
2. [Core Operating Principles](#2-core-operating-principles)
3. [Critical Technical Rules](#3-critical-technical-rules)
4. [Specialized Rules](#4-specialized-rules)
5. [Architecture Summary](#5-architecture-summary)
6. [Development Commands](#6-development-commands)
7. [Implementation Checklist](#7-implementation-checklist)
8. [Detailed Documentation](#8-detailed-documentation)

---

## 1. Project Overview

The Monitored App is a **Flutter-based monitoring/surveillance application** for the XP SafeConnect ecosystem, designed for **legitimate parental control and family safety use cases**.

### Technology Stack
- **Frontend**: Flutter 3.x, Dart
- **State Management**: Riverpod
- **Dependency Injection**: GetIt (service locator pattern)
- **Data Models**: Freezed (immutable models)
- **Local Storage**: SQLite + Flutter Secure Storage
- **Backend**: Django REST API
- **Platforms**: Android (full-featured), iOS (limited functionality)

### Key Architectural Principles
- **Background-first design**: Core functionality runs in background services
- **Native platform integration**: MethodChannels for platform-specific features
- **Modular collectors**: Separate collectors for SMS, calls, location, apps, media
- **Adaptive battery optimization**: Dynamic adjustment based on battery level
- **Multi-mode operation**: Normal, Discrete, and Invisible modes

### Project Context
**CRITICAL**: All implementation must strictly comply with:
- **Specification files** in `docs/` folder
- **API documentation**: `docs/API-Endpoints-Application-Surveillee.md` (primary reference)
- **Development plan**: `docs/monitored-app-development-plan.md`
- **Architecture guides**: Multiple guide files in `docs/`

---

## 2. Core Operating Principles

### Before Acting (10 Essential Checks)

#### 1. Strict Compliance With Project Specifications
✅ **ALWAYS**: Comply with ALL documents in `docs/` folder
✅ **Primary API Reference**: `docs/API-Endpoints-Application-Surveillee.md`
✅ **Structure**: Code for easy dev → prod switching

```dart
// ✅ CORRECT: Environment-aware configuration
final apiUrl = BuildConfig.isProduction
    ? 'https://api.xpsafeconnect.com'
    : 'http://localhost:8000';

// ❌ WRONG: Hardcoded production URL in code
final apiUrl = 'https://api.xpsafeconnect.com';
```

#### 2. Respect the Development Plan
✅ **ALWAYS**: Follow step order in `docs/monitored-app-development-plan.md`
✅ **ALWAYS**: Align with established architectural decisions

#### 3. Ensure You Have All Necessary Information
✅ **Before responding**: Verify you have all details
✅ **If unclear**: Ask precise questions before proceeding
✅ **Never assume**: Always clarify ambiguities

#### 4. Internationalization (i18n)
✅ **REQUIRED**: Support French (primary) and English
✅ **UI elements**: All text via `app_en.arb` / `app_fr.arb`
✅ **Error messages**: Internationalized
✅ **Internal naming**: Avoid language-specific text in logic

```dart
// ✅ CORRECT
Text(AppLocalizations.of(context)!.welcomeMessage);

// ❌ WRONG
Text('Bienvenue'); // Hardcoded French
```

#### 5. Real-World, Production-Valid Implementation
✅ **ONLY implement**: Real production-ready solutions
❌ **AVOID**: Temporary/hardcoded values, static test data, isolated mock logic
✅ **Structure**: Easy dev → prod switch

#### 6. Consistency and Regression Avoidance
✅ **ALWAYS**: Ensure no negative impact on existing features
✅ **CHECK**: Existing flows, security requirements, backend–frontend contract
✅ **RUN**: `flutter analyze` before committing

#### 7. Error Correction
✅ **ALWAYS consider**: Project specs, implementation context, module interactions
✅ **NO regressions**: Ensure fix doesn't introduce new issues
✅ **IF backend change needed**: Provide detailed instructions (what, where, why)

#### 8. Coordination With Backend
✅ **Frontend fix requiring backend change**: Provide clear, actionable backend instructions
✅ **Backend work requiring frontend change**: Provide clear, actionable frontend instructions
✅ **ALWAYS**: Ensure alignment with project specifications

#### 9. Summaries and Progress Tracking
✅ **After each work package**: Provide precise, concise summary
✅ **Include**: What has been implemented, what remains
✅ **Format**: Clear, actionable next steps

#### 10. Execution Environment
✅ **Prefer**: Command Prompt for commands
✅ **Alternative**: PowerShell if more efficient
✅ **Platform**: Windows development environment

#### 11. Double Check Completion (Mandatory)
✅ **ALWAYS**: Reject the first completion attempt.
✅ **ALWAYS**: Re-verify the work against the original task requirements before final response.
✅ **ALWAYS**: Only finalize after an explicit second-pass verification confirms completeness and no missing requirement.

---

#### 12. Task Orchestrator (Mandatory — see top of this file)
✅ **ALWAYS**: The very first action for any request is to read `skills/task-orchestrator/SKILL.md` and invoke the matching skill(s).
✅ **NEVER**: Skip orchestration, even for questions that seem trivial.
✅ **Reference**: See the **MANDATORY FIRST ACTION** section at the top of this file.

### During Implementation

✅ **Complete code**: No placeholders, no `// TODO`, no pseudocode
✅ **Production-valid**: Real-world solutions only
✅ **Follow patterns**: Analyze surrounding code, match existing style
✅ **Check regressions**: Verify no existing functionality breaks
✅ **Test features**: Manual verification on device/emulator
✅ **Exact file paths**: Always specify full, absolute paths
✅ **Security-aware**: Handle sensitive data securely, no leaks in logs

### After Implementation

✅ **Summarize work**: Precise, concise summary of changes
✅ **List remaining tasks**: Clear next steps
✅ **Backend impact**: Document any backend changes required
✅ **Integration issues**: Create issue documentation file if needed
✅ **Code quality**: Ensure `flutter analyze` passes (zero warnings)

---

## 3. Critical Technical Rules

**⚠️ THESE RULES MUST NEVER BE VIOLATED**

### Rule 1: Use Dependency Injection via GetIt

All services must be accessed through the GetIt service locator (`lib/app/locator.dart`). Never instantiate services directly.

```dart
// ✅ CORRECT
final authService = locator<AuthService>();
final storageService = locator<StorageService>();
await authService.login(credentials);

// ❌ WRONG
final authService = AuthService(); // Direct instantiation
```

**Why**: Ensures singleton pattern, testability, and centralized lifecycle management.

**Config**: Service registration in `lib/app/locator.dart`

---

### Rule 2: Use Riverpod for State Management

UI state must be managed with Riverpod. Do not use StatefulWidgets for complex state.

```dart
// ✅ CORRECT
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myState = ref.watch(myProvider);
    return Text(myState.message);
  }
}

// For callbacks
onPressed: () {
  ref.read(myProvider.notifier).updateState();
}

// ❌ WRONG
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  String message = '';
  // Manual state management
}
```

**Why**: Provides reactive state management, better testability, and cleaner separation of concerns.

**Config**: Providers defined as global constants in feature files.

---

### Rule 3: Background-First Design

Core monitoring logic (data collection, syncing) belongs in background services (`lib/core/services/`), not the UI layer.

```dart
// ✅ CORRECT
// In lib/core/services/data_collector_service.dart
class DataCollectorService {
  Future<void> collectSmsData() async {
    final smsList = await _smsCollector.collect();
    await _storageService.saveSmsData(smsList);
  }
}

// In UI widget
onPressed: () {
  // Just trigger the service
  locator<DataCollectorService>().startCollection();
}

// ❌ WRONG
// Complex data collection logic in a widget build method
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        // Complex collection logic here - WRONG!
        final smsList = await platform.invokeMethod('getSms');
        // ... 50 lines of data processing ...
      },
    );
  }
}
```

**Why**: Ensures monitoring continues even when UI is closed. Separates concerns.

**Architecture**: See `@.claude/rules/architecture-detailed.md`

---

### Rule 4: Use Native Bridges for Platform Features

Access platform-specific APIs (SMS, Call Logs, Camera on Android) through established MethodChannel bridges in `android/app/src/main/kotlin/`.

```dart
// ✅ CORRECT
// In lib/core/collectors/sms_collector.dart
class SmsCollector {
  static const _channel = MethodChannel('com.xpsafeconnect/sms');

  Future<List<SmsMessage>> collect() async {
    final List<dynamic> result = await _channel.invokeMethod('getSmsMessages');
    return result.map((e) => SmsMessage.fromJson(e)).toList();
  }
}

// ❌ WRONG
// Trying to access Android APIs directly from Dart (impossible)
import 'package:android_sms/android_sms.dart'; // Non-existent
```

**Why**: Flutter cannot directly access platform APIs. MethodChannels bridge Dart ↔ Native.

**Native Files**:
- Android: `android/app/src/main/kotlin/.../SmsCollectorPlugin.kt`
- iOS: `ios/Runner/` (limited features)

---

### Rule 5: Internationalize All User-Facing Text

Use localization files (`app_en.arb`, `app_fr.arb`) for ALL text displayed in the UI. No hardcoded strings.

```dart
// ✅ CORRECT
Text(AppLocalizations.of(context)!.welcomeMessage);
Text(AppLocalizations.of(context)!.errorOccurred);

// Localization files
// lib/l10n/app_en.arb
{
  "welcomeMessage": "Welcome to XP SafeConnect",
  "errorOccurred": "An error occurred"
}

// lib/l10n/app_fr.arb
{
  "welcomeMessage": "Bienvenue sur XP SafeConnect",
  "errorOccurred": "Une erreur s'est produite"
}

// ❌ WRONG
Text('Welcome to XP SafeConnect'); // Hardcoded English
Text('Une erreur s\'est produite'); // Hardcoded French
```

**Why**: App must support French (primary) and English. Hardcoded strings break localization.

**Config**: `l10n.yaml`, `lib/l10n/`

---

### Rule 6: Handle Errors Gracefully and Securely

Wrap all fallible operations (network, platform calls, I/O) in try-catch blocks. Do not expose sensitive information in error messages. Use Firebase Crashlytics for reporting.

```dart
// ✅ CORRECT
Future<void> syncData() async {
  try {
    final data = await _storageService.getPendingData();
    await _apiClient.syncData(data);
    await _storageService.markAsSynced(data);
  } on DioException catch (e, stackTrace) {
    // Log to Crashlytics (secure, remote)
    await FirebaseCrashlytics.instance.recordError(
      e,
      stackTrace,
      reason: 'Data sync failed',
      information: ['User: ${_authService.userId}'], // Safe info only
    );

    // Show generic error to user
    _notificationService.showError(
      AppLocalizations.of(context)!.syncErrorMessage,
    );
  } catch (e, stackTrace) {
    // Catch-all for unexpected errors
    await FirebaseCrashlytics.instance.recordError(e, stackTrace);
  }
}

// ❌ WRONG
Future<void> syncData() async {
  final data = await _storageService.getPendingData(); // No error handling!
  await _apiClient.syncData(data); // Can fail!
}

// ❌ WRONG: Exposes sensitive info
catch (e) {
  print('API Error: $e'); // Logs error details (may contain tokens, data)
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('Error'),
      content: Text('Failed: ${e.toString()}'), // Exposes error details to user
    ),
  );
}
```

**Why**: Network/platform calls can fail. Users should see friendly messages. Detailed errors go to Crashlytics for debugging.

**Config**: Firebase setup in `lib/firebase_options.dart`

---

## 4. Specialized Rules

### Integration Issue Documentation Rule

When you detect an integration issue (backend API error, unexpected data format, authentication failure, CORS, etc.), you **MUST automatically create** a markdown file documenting it.

**Triggers**:
- HTTP 4xx/5xx errors from backend
- Data format mismatches (expected object, got array)
- Authentication/authorization failures (403, 401)
- WebSocket connection failures
- Unexpected null values in critical fields
- CORS errors (web platform)

**File Naming**: `docs/integration_issues/INTEGRATION_ISSUE_[TYPE]_[DESC]_[YYYYMMDD].md`
- `[TYPE]`: `API_500`, `DATA_MISMATCH`, `AUTH_403`, `WS_DISCONNECT`, etc.
- `[DESC]`: One-or-two-word description (e.g., `SyncEndpoint`, `UserProfile`)
- `[YYYYMMDD]`: Current date (e.g., `20260123`)

**Example**: `docs/integration_issues/INTEGRATION_ISSUE_API_500_SyncEndpoint_20260123.md`

**Template**: See `@.claude/rules/integration-issue-documentation.md` for the complete 9-section template.

**Process**:
1. Detect issue during development/testing
2. Create file with template
3. Fill all required sections, including the conditional frontend-remediation section when applicable
4. Inform user of issue and file creation
5. Provide backend team with actionable next steps

---

## 5. Architecture Summary

The app follows a **4-layer architecture**:

```
┌─────────────────────────────────────────┐
│  Layer 4: Features (UI)                 │
│  lib/features/                          │
│  - auth/, home/                         │
│  - Uses Riverpod for state             │
└─────────────────────────────────────────┘
           ↓ uses ↓
┌─────────────────────────────────────────┐
│  Layer 1: Service Layer                 │
│  lib/core/services/                     │
│  - BackgroundService, AuthService       │
│  - WebSocketService, StorageService     │
│  - Registered in GetIt                  │
└─────────────────────────────────────────┘
           ↓ uses ↓
┌─────────────────────────────────────────┐
│  Layer 2: Data Collectors               │
│  lib/core/collectors/                   │
│  - SmsCollector, CallsCollector         │
│  - LocationCollector, MediaCollector    │
│  - Inherit from BaseCollector           │
└─────────────────────────────────────────┘
           ↓ calls ↓
┌─────────────────────────────────────────┐
│  Layer 3: Native Bridges                │
│  android/app/src/main/kotlin/           │
│  ios/Runner/                            │
│  - MethodChannels bridge Dart ↔ Native │
└─────────────────────────────────────────┘
```

**Key Services**:
- `BackgroundService`: Main orchestrator for continuous operation
- `WebSocketService`: Real-time backend communication
- `BatteryMonitorService`: Power optimization and adaptive behavior
- `AuthService`: JWT-based authentication with auto-refresh
- `StorageService`: Secure local storage (SQLite + Secure Storage)
- `DataCollectorService`: Coordinates all data collection activities

**Data Flow**:
1. Native collectors gather data continuously
2. Data compressed, encrypted, cached in SQLite
3. Background sync service batches and uploads via WebSocket/HTTP
4. Real-time commands received via WebSocket
5. Emergency mode triggers high-frequency collection

**For detailed architecture**: `@.claude/rules/architecture-detailed.md`

---

## 6. Development Commands

### Running the App
```bash
# Run in debug mode
flutter run

# Run with specific flavor (if configured)
flutter run --flavor dev
```

### Testing
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run with coverage
flutter test --coverage
```

### Code Quality
```bash
# Static analysis (must pass with zero warnings)
flutter analyze

# Format code
dart format .

# Fix common issues
dart fix --apply
```

### Code Generation
```bash
# Generate Freezed models, JSON serialization
dart run build_runner build

# Force regenerate (delete conflicting outputs)
dart run build_runner build --delete-conflicting-outputs

# Watch mode (auto-regenerate on file changes)
dart run build_runner watch
```

### Dependencies
```bash
# Install dependencies
flutter pub get

# Upgrade dependencies
flutter pub upgrade

# Clean build artifacts
flutter clean
```

### Building
```bash
# Build Android APK
flutter build apk

# Build Android App Bundle (for Play Store)
flutter build appbundle

# Build iOS (requires macOS)
flutter build ios
```

---

## 7. Implementation Checklist

### Quick Checklist (Essential)

**Critical Technical Rules** (6 Rules):
- [ ] ✅ Rule 1: GetIt dependency injection (no direct service instantiation)
- [ ] ✅ Rule 2: Riverpod for state management (no complex StatefulWidget)
- [ ] ✅ Rule 3: Background-first design (logic in services, not UI)
- [ ] ✅ Rule 4: MethodChannels for native features (no direct platform access)
- [ ] ✅ Rule 5: Internationalized text (no hardcoded strings)
- [ ] ✅ Rule 6: Error handling with Crashlytics (no exposed sensitive info)

**Core Operating Principles**:
- [ ] ✅ Complies with specs in `docs/` folder
- [ ] ✅ Follows development plan step order
- [ ] ✅ Production-valid implementation (no hardcoded values)
- [ ] ✅ No regressions (existing features still work)
- [ ] ✅ Backend impact assessed (instructions provided if needed)

**Quality**:
- [ ] ✅ `flutter analyze` passes (zero warnings)
- [ ] ✅ Code formatted with `dart format`
- [ ] ✅ Integration issue file created (if applicable)
- [ ] ✅ Summary provided (what's done, what remains)

**For complete 44-item checklist**: `@.claude/rules/implementation-checklist.md`

---

## 8. Detailed Documentation (On-Demand)

Load these files when you need detailed information on specific topics. They are automatically imported when relevant to the conversation context.

- **Detailed Architecture**: `@.claude/rules/architecture-detailed.md`
  Full breakdown of layers, services, collectors, native bridges, data flow

- **Detailed Code Style Guide**: `@.claude/rules/code-style-detailed.md`
  Formatting, naming conventions, async patterns, widget structure, Riverpod, Freezed models

- **Full Implementation Checklist**: `@.claude/rules/implementation-checklist.md`
  44-item comprehensive checklist covering planning, implementation, security, testing, documentation, platform considerations

- **Integration Issue Documentation Template**: `@.claude/rules/integration-issue-documentation.md`
  Complete 8-section template for documenting backend/integration issues

---

## Summary

This is a **Flutter-based monitoring application** designed for **legitimate parental control and family safety**. It emphasizes:

1. **Strict compliance** with project specifications in `docs/`
2. **Background-first architecture** for continuous monitoring
3. **6 critical technical rules** that must never be violated
4. **Production-ready code** with proper error handling and internationalization
5. **Security and privacy** through secure storage and minimal data exposure

**Primary workflow**: Always read specs → follow development plan → implement with critical rules → test thoroughly → document integration issues → provide clear summary.

**Remember**: The monitoring capabilities require explicit user consent and are intended for **authorized device supervision only**.

---

**Version**: 2.0 (Complete & Optimized) | **Date**: 23/01/2026 | **Token-Optimized**: ~800 lines → ~600 lines with imports

## Additional Cross-Agent Rules (2026-03-06)
- Frontend log sweep: During log analysis for a task, also fix unrelated frontend errors found in the same logs when the fix is low-risk and in scope.
- Backend issue reporting: If analysis indicates a backend-side issue, create a detailed, structured markdown report describing the problem and the proposed solution; if and only if part of the issue also concerned frontend and that frontend part is already resolved, include a dedicated detailed section describing exactly what was already implemented on frontend side.
- Monitor app issue reporting: If analysis indicates an issue in the monitor app frontend, create a detailed, structured markdown report describing the problem and the proposed solution.

## Virtual Environment Rule (2026-05-21) — ALL AGENTS, ALL COMMANDS

**MANDATORY**: Every command execution must run inside the project's Python virtual environment located at `.venv/` at the project root.

Claude Code enforces this automatically via `PreToolUse` hooks (`.claude/hooks/`). As a model, you must also follow this rule explicitly when constructing commands.

### Activation syntax by shell

| Shell | Activation command |
| ----- | ------------------ |
| **PowerShell** | `. '.venv\Scripts\Activate.ps1'` |
| **CMD** | `.venv\Scripts\activate.bat` (or just `.venv\Scripts\activate`) |
| **Bash / Git Bash** | `source ".venv/Scripts/activate"` (Windows) or `source ".venv/bin/activate"` (Linux/Mac) |

### Rules for model-generated commands

- **PowerShell tool**: Always prepend `. '.venv\Scripts\Activate.ps1';` before the command.
- **Bash tool**: Always prepend `source ".venv/Scripts/activate" 2>/dev/null || source ".venv/bin/activate" 2>/dev/null;` before the command.
- **CMD context** (manual instructions to user): Instruct to run `.venv\Scripts\activate` first, then the command.
- The activation is idempotent — prepending it even when venv is already active is safe.
- If `.venv` does not exist at the time a command runs, activation silently fails and the command proceeds normally.

---

## 🔒 Règles de Cache Prompt (ne pas modifier pendant une session active)

Le cache Anthropic est actif avec TTL=1h (`ENABLE_PROMPT_CACHING_1H=1`).
Il repose sur un alignement strict gauche→droite :
  Outils MCP → Prompt Système → CLAUDE.md / Skills → Messages

### Règles impératives pour maintenir le cache intact

1. **Gel des outils MCP** : Initialiser tous les serveurs MCP AVANT de démarrer
   Claude Code. Ne jamais ajouter, retirer ou modifier un outil MCP en cours de session.

2. **Gel de ce fichier** : Ne pas éditer CLAUDE.md pendant une tâche en cours.
   Toute modification physique invalide immédiatement le cache pour le tour suivant.
   → Utiliser les skills (`.claude/skills/`) pour les règles opérationnelles changeantes.

3. **Gel du modèle** : Ne pas changer de modèle via `/model` en cours de session.
   Chaque modèle a une partition de cache distincte — changer = reconstruire à 1.25x.

4. **Gain attendu** : session 20 tours → 28 400 tokens au lieu de 184 000 (−85%).
