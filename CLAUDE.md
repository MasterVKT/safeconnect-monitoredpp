# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Flutter Commands
- `flutter run` - Run the app in debug mode
- `flutter build apk` - Build Android APK
- `flutter build ios` - Build iOS app  
- `flutter test` - Run all tests
- `flutter analyze` - Static analysis
- `flutter pub get` - Install dependencies
- `flutter pub upgrade` - Upgrade dependencies
- `flutter clean` - Clean build artifacts

### Code Generation
- `dart run build_runner build` - Generate code (Freezed models, JSON serialization)
- `dart run build_runner build --delete-conflicting-outputs` - Force regenerate

### Testing
- `flutter test test/widget_test.dart` - Run single test file

## Architecture Overview

This is a Flutter-based **monitoring/surveillance application** that collects data from devices and syncs to a backend. The app is designed for **continuous background operation** with minimal battery impact.

### Key Architectural Principles
- **Background-first design**: Core functionality runs in background services
- **Native platform integration**: Heavy use of Android/iOS native code via MethodChannels
- **Modular collectors**: Separate collectors for SMS, calls, location, apps, media
- **Adaptive battery optimization**: Dynamic adjustment based on battery level
- **Multi-mode operation**: Normal, discrete, and invisible modes

### Core Architecture Layers

#### 1. Service Layer (`lib/core/services/`)
- **BackgroundService**: Main orchestrator for continuous operation
- **WebSocketService**: Real-time communication with backend
- **BatteryMonitorService**: Power optimization and adaptive behavior
- **AuthService**: JWT-based authentication with auto-refresh
- **StorageService**: Secure local storage wrapper
- **ConnectivityService**: Network state monitoring
- **DataCollectorService**: Coordinates all data collection activities
- **NotificationService**: Manages app notifications
- **UnlockService**: Device unlock detection and handling

#### 2. Data Collectors (`lib/core/collectors/`)
- **BaseCollector**: Abstract collector with common functionality (caching, retry, compression)
- **LocationCollector**: GPS tracking with adaptive frequency
- **SmsCollector**: SMS monitoring (Android only)
- **CallsCollector**: Call log monitoring (Android only)
- **AppsCollector**: App usage tracking
- **MediaCollector**: Photo/audio capture capabilities

#### 3. Native Bridges (`android/app/src/main/kotlin/`)
- **AppsCollectorPlugin.kt**: Native Android app usage collection
- **BackgroundCollectorService.kt**: Android foreground service
- **CallsCollectorPlugin.kt**: Call log access
- **SmsCollectorPlugin.kt**: SMS database monitoring
- **MediaCapturePlugin.kt**: Camera/microphone access
- **BatteryOptimizationPlugin.kt**: Power management integration
- **UnlockDevicePlugin.kt**: Device unlock detection
- **BootCompletedReceiver.kt**: Auto-start after device boot
- **MainActivity.kt**: Main activity with MethodChannel setup

#### 4. Features (`lib/features/`)
- **auth/**: Device pairing and user consent (models, repositories, viewmodels, views)
  - `pairing_screen.dart`: Initial device pairing with code entry
  - `permission_screen.dart`: Permission request flow
  - `setup_complete_screen.dart`: Setup completion confirmation
- **home/**: Minimal UI (main screen, emergency mode, shared data view)
  - `main_screen.dart`: Primary app interface 
  - `emergency_screen.dart`: Emergency mode activation
  - `shared_data_screen.dart`: Data sharing status

### Key Technical Details

#### Dependency Injection
- Uses **GetIt** service locator pattern
- Setup in `lib/app/locator.dart`
- Services registered as singletons for lifecycle management

#### State Management
- **Riverpod** for UI state
- **Freezed** for immutable data models
- Local SQLite for data persistence

#### Background Operation
- **Foreground Service** on Android with persistent notification
- **Boot receiver** for auto-start capability
- **Isolate communication** between main app and background service
- **WorkManager** fallback for scheduled tasks

#### Battery Optimization Strategy
- Adaptive collection intervals based on battery level (100-50%: normal, 50-30%: reduced, etc.)
- Network-aware syncing (WiFi preferred)
- Compression and batching for efficiency

#### Security Features
- **Flutter Secure Storage** for sensitive data
- **Firebase Crashlytics** for error tracking
- **Device Admin API** integration for tamper resistance
- Encryption of collected data before storage

#### Platform-Specific Limitations
- **Android**: Full feature set with native collectors
- **iOS**: Limited to location and basic monitoring due to platform restrictions

### Data Flow
1. Native collectors gather data continuously
2. Data compressed and cached locally in SQLite
3. Background sync service batches and uploads via WebSocket/HTTP
4. Real-time commands received via WebSocket for immediate actions
5. Emergency mode triggers high-frequency collection and priority sync

### Configuration
- Multi-environment support through `AppConfig` in `lib/core/config/`
- Build flavors for debug/release/stealth modes
- Firebase integration for push notifications and crash reporting
- Localization support (French primary via `app_fr.arb`, English secondary via `app_en.arb`)
- `firebase.json` and `firebase_options.dart` for Firebase configuration
- `analysis_options.yaml` with Flutter lints enabled

### Entry Points
- **Main app**: `lib/main.dart` - Primary application entry with Firebase setup
- **Background service**: `lib/background_service_entry.dart` - Isolate entry for background tasks
- **App configuration**: `lib/app/app.dart` - Root widget with routing and theming

## Important Context for Development

This application is designed for **legitimate parental control and family safety use cases**. The monitoring capabilities require explicit user consent and are intended for authorized device supervision only.

The codebase emphasizes reliability and stealth operation while maintaining legal compliance through proper consent mechanisms and transparency features.

## Description
This is the monitored app of the **monitoring/surveillance application**

## Others rules

The other rules for this project are located in the `.cursor/rules`folder at the root of the project. You should apply these rules intelligently: for every command you execute or output you generate, determine which rule is relevant based on the context of the task, its description, and the rule’s content.