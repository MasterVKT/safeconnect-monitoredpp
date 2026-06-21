import 'package:get_it/get_it.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:monitored_app/core/api/api_client.dart';
import 'package:monitored_app/core/config/app_config.dart';
import 'package:monitored_app/core/services/auth_service.dart';
import 'package:monitored_app/core/services/connectivity_service.dart';
import 'package:monitored_app/core/services/storage_service.dart';
import 'package:monitored_app/core/services/websocket_service.dart';
import 'package:monitored_app/core/services/unlock_service.dart';
import 'package:monitored_app/core/services/battery_monitor_service.dart';
import 'package:monitored_app/core/services/battery_optimization_service.dart';
import 'package:monitored_app/core/services/collection_ownership_service.dart';
import 'package:monitored_app/core/services/data_collector_service.dart';
import 'package:monitored_app/core/services/background_service.dart';
import 'package:monitored_app/core/services/database_service.dart';
import 'package:monitored_app/core/services/security_service.dart';
import 'package:monitored_app/core/services/device_service.dart';
import 'package:monitored_app/core/services/emergency_service.dart';
import 'package:monitored_app/core/services/notification_service.dart';
import 'package:monitored_app/core/services/stealth_service.dart';
import 'package:monitored_app/core/services/anti_tamper_service.dart';
import 'package:monitored_app/core/services/advanced_media_service.dart';
import 'package:monitored_app/core/services/rasp_service.dart';
import 'package:monitored_app/core/services/security_monitoring_service.dart';
import 'package:monitored_app/core/services/contact_resolution_service.dart';
import 'package:monitored_app/core/monitoring/performance_monitor.dart';
import 'package:monitored_app/core/monitoring/performance_optimizer.dart';
import 'package:monitored_app/core/monitoring/test_validation_service.dart';
import 'package:monitored_app/core/privacy/consent_manager.dart';
import 'package:monitored_app/core/network/p2p_communication_service.dart';
import 'package:monitored_app/core/network/p2p_signaling_service.dart';
import 'package:monitored_app/core/network/p2p_command_handler.dart';
import 'package:monitored_app/core/network/p2p_manager.dart';
import 'package:monitored_app/core/network/production_webrtc_service.dart';
import 'package:monitored_app/core/network/p2p_file_transfer_service.dart';
import 'package:monitored_app/features/auth/repositories/auth_repository.dart';
import 'package:monitored_app/core/services/media_upload_service.dart';
import 'package:monitored_app/core/sync/sync_status_monitor.dart';

final GetIt locator = GetIt.instance;

Future<void> setupLocator() async {
  if (locator.isRegistered<StorageService>()) {
    return;
  }

  Future<void> initializeOptionalService(
      String name, Future<void> Function() initialize) async {
    try {
      await initialize();
    } catch (e, stackTrace) {
      debugPrint('Optional service initialization failed ($name): $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  // Services externes
  final sharedPreferences = await SharedPreferences.getInstance();
  locator.registerSingleton<SharedPreferences>(sharedPreferences);

  locator.registerSingleton<FlutterSecureStorage>(const FlutterSecureStorage());

  // Services de base
  locator.registerLazySingleton<ApiClient>(() => ApiClient());

  locator.registerLazySingleton<StorageService>(() => StorageService(
        locator<SharedPreferences>(),
        locator<FlutterSecureStorage>(),
      ));

  locator
      .registerLazySingleton<ConnectivityService>(() => ConnectivityService());
  locator.registerLazySingleton<UnlockService>(() => UnlockService());
  locator.registerLazySingleton<ContactResolutionService>(
      () => ContactResolutionService());

  // WebSocketService registered here — before ALL services that may use it
  locator.registerLazySingleton<WebSocketService>(() => WebSocketService());

  // Database service (singleton - initialize early)
  final databaseService = DatabaseService.instance;
  await databaseService.initialize();
  locator.registerSingleton<DatabaseService>(databaseService);
  locator.registerLazySingleton<CollectionOwnershipService>(
      () => CollectionOwnershipService());

  // Security service (singleton - initialize early for security checks)
  final securityService = SecurityService();
  if (!kDebugMode) {
    await securityService.initialize();
  } else {
    debugPrint('Skipping SecurityService.initialize() in debug mode');
  }
  locator.registerSingleton<SecurityService>(securityService);

  // Notification service (initialize early for emergency notifications)
  locator
      .registerLazySingleton<NotificationService>(() => NotificationService());

  // Emergency service (initialize after database and notification services)
  final emergencyService = EmergencyService();
  if (!kDebugMode) {
    await emergencyService.initialize();
  } else {
    debugPrint('Skipping EmergencyService.initialize() in debug mode');
  }
  locator.registerSingleton<EmergencyService>(emergencyService);

  // Stealth service (initialize after database service)
  final stealthService = StealthService();
  if (!kDebugMode) {
    await stealthService.initialize();
  } else {
    debugPrint('Skipping StealthService.initialize() in debug mode');
  }
  locator.registerSingleton<StealthService>(stealthService);

  // Anti-tamper service (initialize after security service)
  final antiTamperService = AntiTamperService();
  if (!kDebugMode) {
    await antiTamperService.initialize();
  } else {
    debugPrint('Skipping AntiTamperService.initialize() in debug mode');
  }
  locator.registerSingleton<AntiTamperService>(antiTamperService);

  // Advanced Media Service (initialize after other core services)
  final advancedMediaService = AdvancedMediaService();
  await initializeOptionalService(
      'AdvancedMediaService', advancedMediaService.initialize);
  locator.registerSingleton<AdvancedMediaService>(advancedMediaService);

  // RASP Service (initialize after security service for runtime protection)
  final raspService = RASPService();
  if (!kDebugMode) {
    await initializeOptionalService('RASPService', raspService.initialize);
  } else {
    debugPrint('Skipping RASPService.initialize() in debug mode');
  }
  locator.registerSingleton<RASPService>(raspService);

  // Security Monitoring Service (initialize after all security services)
  final securityMonitoringService = SecurityMonitoringService();
  if (!kDebugMode) {
    await initializeOptionalService(
        'SecurityMonitoringService', securityMonitoringService.initialize);
  } else {
    debugPrint('Skipping SecurityMonitoringService.initialize() in debug mode');
  }
  locator
      .registerSingleton<SecurityMonitoringService>(securityMonitoringService);

  // Services d'authentification
  locator.registerLazySingleton<AuthService>(() => AuthService(
        locator<ApiClient>(),
        locator<StorageService>(),
      ));
  // Service de surveillance de batterie
  final batteryMonitorService = BatteryMonitorService();
  await batteryMonitorService.initialize();
  locator.registerSingleton<BatteryMonitorService>(batteryMonitorService);

  // Performance Optimizer (initialized after battery monitor to avoid DI cycle)
  final performanceOptimizer = PerformanceOptimizer();
  await initializeOptionalService(
      'PerformanceOptimizer', performanceOptimizer.initialize);
  locator.registerSingleton<PerformanceOptimizer>(performanceOptimizer);

  // Service d'optimisation de batterie
  locator.registerLazySingleton<BatteryOptimizationService>(
      () => BatteryOptimizationService());

  // Sync Status Monitor (initialize before data collector service)
  final syncStatusMonitor = SyncStatusMonitor();
  await syncStatusMonitor.initialize();
  locator.registerSingleton<SyncStatusMonitor>(syncStatusMonitor);

  // Service de collecte de données
  locator.registerLazySingleton<DataCollectorService>(
      () => DataCollectorService());

  // Service d'upload de fichiers médias (dernier chaînon de la chaîne médias)
  locator.registerLazySingleton<MediaUploadService>(
    () => MediaUploadService(
      locator<ApiClient>(),
      locator<ConnectivityService>(),
    ),
  );

  // Service d'arrière-plan
  locator.registerLazySingleton<BackgroundService>(() => BackgroundService());

  // Device management service
  final deviceService = DeviceService();
  await deviceService.initialize();
  locator.registerSingleton<DeviceService>(deviceService);

  // Performance monitoring (keep existing monitor for backwards compatibility)
  final performanceMonitor = PerformanceMonitor();
  await performanceMonitor.initialize();
  locator.registerSingleton<PerformanceMonitor>(performanceMonitor);

  // Consent management
  final consentManager = ConsentManager();
  await consentManager.initialize();
  locator.registerSingleton<ConsentManager>(consentManager);

  // P2P Communication services
  final p2pCommunicationService = P2PCommunicationService();
  await initializeOptionalService(
      'P2PCommunicationService', p2pCommunicationService.initialize);
  locator.registerSingleton<P2PCommunicationService>(p2pCommunicationService);

  final p2pSignalingService = P2PSignalingService();
  await initializeOptionalService(
      'P2PSignalingService', p2pSignalingService.initialize);
  locator.registerSingleton<P2PSignalingService>(p2pSignalingService);

  final p2pCommandHandler = P2PCommandHandler();
  await initializeOptionalService(
      'P2PCommandHandler', p2pCommandHandler.initialize);
  locator.registerSingleton<P2PCommandHandler>(p2pCommandHandler);

  // Production WebRTC Service (production-ready WebRTC integration)
  final productionWebRTCService = ProductionWebRTCService();
  await initializeOptionalService(
      'ProductionWebRTCService', productionWebRTCService.initialize);
  locator.registerSingleton<ProductionWebRTCService>(productionWebRTCService);

  // P2P Manager (high-level API)
  final p2pManager = P2PManager();
  await initializeOptionalService('P2PManager', p2pManager.initialize);
  locator.registerSingleton<P2PManager>(p2pManager);

  // P2P File Transfer Service (file transfer capabilities)
  final p2pFileTransferService = P2PFileTransferService();
  await initializeOptionalService(
      'P2PFileTransferService', p2pFileTransferService.initialize);
  locator.registerSingleton<P2PFileTransferService>(p2pFileTransferService);

  // Test Validation Service (comprehensive testing and validation)
  final testValidationService = TestValidationService();
  await initializeOptionalService(
      'TestValidationService', testValidationService.initialize);
  locator.registerSingleton<TestValidationService>(testValidationService);

  // Repositories
  locator.registerLazySingleton<AuthRepository>(() => AuthRepository(
        locator<AuthService>(),
      ));
}

Future<void> setupBackgroundLocator() async {
  if (locator.isRegistered<StorageService>()) {
    return;
  }

  await AppConfig().initialize();

  final sharedPreferences = await SharedPreferences.getInstance();
  locator.registerSingleton<SharedPreferences>(sharedPreferences);
  locator.registerSingleton<FlutterSecureStorage>(const FlutterSecureStorage());

  locator.registerLazySingleton<StorageService>(() => StorageService(
        locator<SharedPreferences>(),
        locator<FlutterSecureStorage>(),
      ));
  locator.registerLazySingleton<ApiClient>(() => ApiClient());
  locator
      .registerLazySingleton<ConnectivityService>(() => ConnectivityService());
  locator.registerLazySingleton<UnlockService>(() => UnlockService());
  locator.registerLazySingleton<ContactResolutionService>(
      () => ContactResolutionService());
  locator.registerLazySingleton<WebSocketService>(() => WebSocketService());
  locator.registerLazySingleton<BatteryOptimizationService>(
      () => BatteryOptimizationService());

  final databaseService = DatabaseService.instance;
  await databaseService.initialize();
  locator.registerSingleton<DatabaseService>(databaseService);
  locator.registerLazySingleton<CollectionOwnershipService>(
      () => CollectionOwnershipService());

  final batteryMonitorService = BatteryMonitorService();
  await batteryMonitorService.initialize();
  locator.registerSingleton<BatteryMonitorService>(batteryMonitorService);

  final syncStatusMonitor = SyncStatusMonitor();
  await syncStatusMonitor.initialize();
  locator.registerSingleton<SyncStatusMonitor>(syncStatusMonitor);

  final deviceService = DeviceService();
  await deviceService.initialize();
  locator.registerSingleton<DeviceService>(deviceService);

  locator.registerLazySingleton<DataCollectorService>(
      () => DataCollectorService());

  locator.registerLazySingleton<MediaUploadService>(
    () => MediaUploadService(
      locator<ApiClient>(),
      locator<ConnectivityService>(),
    ),
  );

  locator.registerLazySingleton<BackgroundService>(() => BackgroundService());
}
