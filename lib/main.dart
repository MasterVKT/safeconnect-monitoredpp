import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monitored_app/app/app.dart';
import 'package:monitored_app/app/locator.dart';
import 'package:monitored_app/background_service_entry.dart';
import 'package:monitored_app/core/config/app_config.dart';
import 'package:monitored_app/core/config/production_config.dart';
import 'package:monitored_app/core/security/build_security.dart';
import 'package:monitored_app/core/services/auth_service.dart';
import 'package:monitored_app/core/services/background_service.dart';
import 'package:monitored_app/core/services/battery_monitor_service.dart';
import 'package:monitored_app/core/services/collection_ownership_service.dart';
import 'package:monitored_app/core/services/data_collector_service.dart';
import 'package:monitored_app/core/services/websocket_service.dart';
import 'package:monitored_app/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (ProductionConfig.isProduction) {
      await BuildSecurity.initializeBuildSecurity();

      if (!ProductionConfig.isValidConfiguration) {
        throw Exception('Production configuration validation failed');
      }
    }

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    if (ProductionConfig.enableCrashlytics) {
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    }

    await AppConfig().initialize();
    await setupLocator();
    WidgetsBinding.instance.addObserver(CollectionLeaseLifecycleObserver());

    final callback =
        PluginUtilities.getCallbackHandle(backgroundServiceEntryPoint);
    final callbackRawHandle = callback?.toRawHandle();
    if (callbackRawHandle != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('callback_handle', callbackRawHandle);
    }

    final ReceivePort port = ReceivePort();
    IsolateNameServer.registerPortWithName(
      port.sendPort,
      'background_isolate_send_port',
    );

    port.listen((message) {
      if (message is Map<String, dynamic>) {
        debugPrint('Main isolate received: ${message['type']}');
      }
    });

    final currentUser = await locator<AuthService>().getCurrentUser();
    if (currentUser != null) {
      FirebaseCrashlytics.instance.setUserIdentifier(currentUser.id);

      await locator<WebSocketService>().connect();
      locator<BatteryMonitorService>().startMonitoring();

      final autoStartEnabled = await AppConfig().isAutoStartEnabled();
      if (autoStartEnabled) {
        await locator<BackgroundService>().startService();
      }
    }

    runApp(
      const ProviderScope(
        child: SafeConnectMonitored(),
      ),
    );
  } catch (error, stackTrace) {
    debugPrint('Bootstrap failure: $error');
    debugPrintStack(stackTrace: stackTrace);

    runApp(
      BootstrapErrorApp(error: error.toString()),
    );
  }
}

class CollectionLeaseLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_releaseMainCollectionLease());
    }
  }

  Future<void> _releaseMainCollectionLease() async {
    try {
      if (!locator.isRegistered<DataCollectorService>()) {
        return;
      }

      await locator<DataCollectorService>().stopCollectors(
        owner: CollectionLeaseOwner.mainIsolate,
      );
    } catch (e, stackTrace) {
      debugPrint('Failed to release main collection lease: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}

class BootstrapErrorApp extends StatelessWidget {
  final String error;

  const BootstrapErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  const Text(
                    'Application startup failed',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
