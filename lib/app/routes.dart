import 'package:flutter/material.dart';
import 'package:monitored_app/features/auth/views/pairing_screen.dart';
import 'package:monitored_app/features/auth/views/permission_screen.dart';
import 'package:monitored_app/features/auth/views/setup_complete_screen.dart';
import 'package:monitored_app/features/home/main_screen.dart';
import 'package:monitored_app/features/home/emergency_screen.dart';
import 'package:monitored_app/features/home/shared_data_screen.dart';

class AppRoutes {
  static const String welcome = '/welcome';
  static const String permissions = '/permissions';
  static const String setupComplete = '/setup-complete';
  static const String home = '/home';
  static const String sharedData = '/shared-data';
  static const String emergency = '/emergency';
}

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.welcome:
        final pairingCode = settings.arguments as String?;
        return MaterialPageRoute(builder: (_) => PairingScreen(pairingCode: pairingCode));
      
      case AppRoutes.permissions:
        return MaterialPageRoute(builder: (_) => const PermissionScreen());
      
      case AppRoutes.setupComplete:
        return MaterialPageRoute(builder: (_) => const SetupCompleteScreen());
      
      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const MainScreen());
      
      case AppRoutes.sharedData:
        return MaterialPageRoute(builder: (_) => const SharedDataScreen());
      
      case AppRoutes.emergency:
        return MaterialPageRoute(builder: (_) => const EmergencyScreen());
      
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Route inconnue: ${settings.name}'),
            ),
          ),
        );
    }
  }
}