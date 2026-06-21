# Detailed Architecture - Monitored App

This document provides a detailed breakdown of the Monitored App's architecture.

## 1. Core Architectural Principles
- **Background-first design**: Core functionality runs in background services to ensure continuous operation without UI.
- **Native platform integration**: Heavy use of Android/iOS native code via MethodChannels for features not available in Flutter.
- **Modular collectors**: Each data type (SMS, calls, location) is handled by a separate, swappable collector module.
- **Adaptive battery optimization**: Collection frequency and data sync strategies adapt dynamically based on battery level.
- **Multi-mode operation**: The app can run in Normal, Discrete, and Invisible modes, altering its visibility and behavior.

## 2. Core Architecture Layers

### Layer 1: Service Layer (`lib/core/services/`)
This layer contains singleton services that manage the app's core functionalities. They are registered in `lib/app/locator.dart` using GetIt.

- **BackgroundService**: The main orchestrator for all background tasks. It runs in a separate Isolate.
- **WebSocketService**: Manages the persistent real-time communication channel with the backend for commands.
- **BatteryMonitorService**: Monitors device battery status and triggers adaptive behavior.
- **AuthService**: Handles JWT-based authentication, including token storage and auto-refresh.
- **StorageService**: A secure wrapper around local SQLite and Flutter Secure Storage for data persistence.
- **ConnectivityService**: Monitors network state (WiFi/cellular) to make intelligent syncing decisions.
- **DataCollectorService**: Coordinates all the individual data collectors.
- **NotificationService**: Manages the persistent foreground service notification on Android.
- **UnlockService**: Detects device unlock events to trigger specific actions.

### Layer 2: Data Collectors (`lib/core/collectors/`)
These are responsible for gathering specific types of data.

- **BaseCollector**: An abstract class with common functionality like caching, retry logic, and data compression.
- **LocationCollector**: GPS and network location tracking with adaptive frequency.
- **SmsCollector**: Monitors the device's SMS database (Android only).
- **CallsCollector**: Monitors the device's call log (Android only).
- **AppsCollector**: Tracks application usage and screen time.
- **MediaCollector**: Provides capabilities for capturing photos and audio on command.

### Layer 3: Native Bridges (`android/app/src/main/kotlin/` and `ios/Runner/`)
This layer handles communication between the Dart code and native platform APIs.

- **Android (`.kt` files)**:
  - `AppsCollectorPlugin`: Native app usage collection.
  - `BackgroundCollectorService`: The Android Foreground Service implementation.
  - `CallsCollectorPlugin`: Call log database access.
  - `SmsCollectorPlugin`: SMS database monitoring.
  - `MediaCapturePlugin`: Native camera and microphone access.
  - `BatteryOptimizationPlugin`: Power management and permission handling.
  - `UnlockDevicePlugin`: BroadcastReceiver for device unlock events.
  - `BootCompletedReceiver`: BroadcastReceiver to auto-start the app after device boot.
  - `MainActivity`: The main entry point for the Android app, where MethodChannels are set up.
- **iOS (`.swift` files)**:
  - `AppDelegate`: Main entry point.
  - `LocationManager`: Handles iOS-specific location tracking.
  - (Other features are limited on iOS due to platform restrictions).

### Layer 4: Features (UI) (`lib/features/`)
This layer contains the application's UI, split by feature. It uses Riverpod for state management.

- **auth/**: Handles device pairing, user consent, and initial setup.
  - `pairing_screen.dart`: UI for entering the pairing code.
  - `permission_screen.dart`: The user-facing flow for requesting necessary device permissions.
  - `setup_complete_screen.dart`: Confirmation screen after setup is done.
- **home/**: The minimal UI shown to the user.
  - `main_screen.dart`: The primary app interface, displaying status.
  - `emergency_screen.dart`: UI for activating emergency mode.
  - `shared_data_screen.dart`: Shows status of data sharing.

## 3. Data Flow

1.  **Collection**: Native collectors or Dart collectors gather data continuously in the background.
2.  **Caching**: Data is compressed, encrypted, and cached locally in a SQLite database.
3.  **Syncing**: The background sync service batches the cached data and uploads it to the backend via a secure HTTP or WebSocket connection. The service prioritizes WiFi over cellular data.
4.  **Commands**: Real-time commands (e.g., "take picture") are received from the backend via the persistent WebSocket connection.
5.  **Emergency Mode**: When triggered, the app enters a high-frequency collection and priority sync mode, ignoring normal battery optimization rules.

## 4. Configuration

- **Environments**: Multi-environment support is managed through `AppConfig` in `lib/core/config/`. This allows switching between debug, release, and stealth modes.
- **Firebase**: `firebase.json` and `lib/firebase_options.dart` configure the connection to Firebase for services like Crashlytics and Push Notifications.
- **Localization**: `l10n.yaml` configures the localization tool, with source files in `lib/l10n/`.
- **Linting**: `analysis_options.yaml` contains strict linting rules from the `flutter_lints` package.

## 5. Entry Points

- **Main App**: `lib/main.dart` is the primary application entry point. It initializes Firebase, GetIt, and the main app widget.
- **Background Service**: `lib/background_service_entry.dart` is the entry point for the background Isolate, ensuring UI and background logic are separated.
