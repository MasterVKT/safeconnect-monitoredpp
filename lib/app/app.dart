import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monitored_app/app/routes.dart';
import 'package:monitored_app/app/theme.dart';
import 'package:monitored_app/features/auth/viewmodels/auth_viewmodel.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SafeConnectMonitored extends ConsumerWidget {
  const SafeConnectMonitored({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Observer l'état d'authentification
    final authState = ref.watch(authViewModelProvider);
    
    return MaterialApp(
      title: 'XP SafeConnect Monitored',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr'),
        Locale('en'),
      ],
      // Décider quelle route initiale afficher en fonction de l'état d'authentification
      initialRoute: authState.maybeWhen(
        authenticated: (_) => AppRoutes.home,
        orElse: () => AppRoutes.welcome,
      ),
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}