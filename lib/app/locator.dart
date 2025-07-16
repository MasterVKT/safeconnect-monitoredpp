import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:monitored_app/core/api/api_client.dart';
import 'package:monitored_app/core/services/auth_service.dart';
import 'package:monitored_app/core/services/connectivity_service.dart';
import 'package:monitored_app/core/services/storage_service.dart';
import 'package:monitored_app/core/services/websocket_service.dart';
import 'package:monitored_app/core/services/unlock_service.dart';
import 'package:monitored_app/core/services/battery_monitor_service.dart';
import 'package:monitored_app/features/auth/repositories/auth_repository.dart';

final GetIt locator = GetIt.instance;

Future<void> setupLocator() async {
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
  
  locator.registerLazySingleton<ConnectivityService>(() => ConnectivityService());
  
  // Services d'authentification
  locator.registerLazySingleton<AuthService>(() => AuthService(
    locator<ApiClient>(),
    locator<StorageService>(),
  ));
  
  // Service WebSocket
  locator.registerLazySingleton<WebSocketService>(() => WebSocketService());
  
  // Service de déverrouillage
  locator.registerLazySingleton<UnlockService>(() => UnlockService());
  
  // Service de surveillance de batterie
  locator.registerLazySingleton<BatteryMonitorService>(() => BatteryMonitorService());
  
  // Repositories
  locator.registerLazySingleton<AuthRepository>(() => AuthRepository(
    locator<AuthService>(),
  ));
}