import 'package:flutter/material.dart';
import 'package:monitored_app/app/routes.dart';
import 'package:monitored_app/app/theme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:monitored_app/core/config/app_config.dart';
import 'package:monitored_app/core/services/background_service.dart';
import 'package:monitored_app/core/services/battery_optimization_service.dart';
import 'package:monitored_app/app/locator.dart';

class SetupCompleteScreen extends StatefulWidget {
  const SetupCompleteScreen({super.key});

  @override
  State<SetupCompleteScreen> createState() => _SetupCompleteScreenState();
}

class _SetupCompleteScreenState extends State<SetupCompleteScreen> {
  DisplayMode _selectedDisplayMode = DisplayMode.normal;
  bool _autoStartEnabled = true;
  NotificationMode _selectedNotificationMode = NotificationMode.visible;
  bool _isLoading = false;
  final BatteryOptimizationService _batteryOptimizationService = locator<BatteryOptimizationService>();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.finalSetup),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Success message
                    Center(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: AppTheme.secondaryColor,
                            size: 80,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.permissionsGranted,
                            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              color: AppTheme.secondaryColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Display mode section
                    Text(
                      l10n.displayMode,
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 8),
                    _buildDisplayModeRadio(DisplayMode.normal, l10n.displayModeNormal, l10n.displayModeNormalDesc),
                    _buildDisplayModeRadio(DisplayMode.discrete, l10n.displayModeDiscrete, l10n.displayModeDiscreteDesc),
                    _buildDisplayModeRadio(DisplayMode.hidden, l10n.displayModeHidden, l10n.displayModeHiddenDesc),
                    const SizedBox(height: 24),
                    
                    // Auto-start section
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.autoStart,
                                style: Theme.of(context).textTheme.displaySmall,
                              ),
                              Text(
                                l10n.autoStartDescription,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _autoStartEnabled,
                          onChanged: (value) {
                            setState(() {
                              _autoStartEnabled = value;
                            });
                          },
                          activeColor: AppTheme.primaryColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Notification mode section
                    Text(
                      l10n.notificationMode,
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 8),
                    _buildNotificationModeRadio(NotificationMode.visible, l10n.notificationModeVisible, l10n.notificationModeVisibleDesc),
                    _buildNotificationModeRadio(NotificationMode.minimized, l10n.notificationModeMinimized, l10n.notificationModeMinimizedDesc),
                    _buildNotificationModeRadio(NotificationMode.hidden, l10n.notificationModeHidden, l10n.notificationModeHiddenDesc),
                    const SizedBox(height: 24),
                    
                    // Information about running in background
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.info_outline, color: AppTheme.primaryColor),
                              const SizedBox(width: 8),
                              Text(
                                l10n.importantInfo,
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.backgroundServiceInfo,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom navigation bar with finish button
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _finishSetup,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : Text(l10n.finishSetup),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDisplayModeRadio(DisplayMode mode, String title, String description) {
    return RadioListTile<DisplayMode>(
      title: Text(title),
      subtitle: Text(description),
      value: mode,
      groupValue: _selectedDisplayMode,
      onChanged: (DisplayMode? value) {
        if (value != null) {
          setState(() {
            _selectedDisplayMode = value;
          });
        }
      },
      activeColor: AppTheme.primaryColor,
    );
  }
  
  Widget _buildNotificationModeRadio(NotificationMode mode, String title, String description) {
    return RadioListTile<NotificationMode>(
      title: Text(title),
      subtitle: Text(description),
      value: mode,
      groupValue: _selectedNotificationMode,
      onChanged: (NotificationMode? value) {
        if (value != null) {
          setState(() {
            _selectedNotificationMode = value;
          });
        }
      },
      activeColor: AppTheme.primaryColor,
    );
  }
  
  Future<void> _finishSetup() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Sauvegarder les configurations dans AppConfig
      await AppConfig().saveInitialConfig(
        _getDisplayModeString(_selectedDisplayMode),
        _getNotificationModeString(_selectedNotificationMode),
        _autoStartEnabled,
      );
      
      // Gérer le démarrage automatique et l'optimisation de batterie
      if (_autoStartEnabled) {
        // Vérifier si l'optimisation de batterie est déjà désactivée
        final isBatteryOptDisabled = await _batteryOptimizationService.isBatteryOptimizationDisabled();
        if (!isBatteryOptDisabled) {
          await _batteryOptimizationService.requestBatteryOptimizationDisable();
        }
        
        // Démarrer le service d'arrière-plan
        await locator<BackgroundService>().startService();
      }
      
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } catch (e) {
      // Afficher un message d'erreur
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.errorOccurred),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.close),
              ),
            ],
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Méthodes d'aide pour convertir les énumérations en chaînes
  String _getDisplayModeString(DisplayMode mode) {
    switch (mode) {
      case DisplayMode.normal:
        return 'NORMAL';
      case DisplayMode.discrete:
        return 'DISCRETE';
      case DisplayMode.hidden:
        return 'HIDDEN';
    }
  }

  String _getNotificationModeString(NotificationMode mode) {
    switch (mode) {
      case NotificationMode.visible:
        return 'VISIBLE';
      case NotificationMode.minimized:
        return 'MINIMIZED';
      case NotificationMode.hidden:
        return 'HIDDEN';
    }
  }
}

enum DisplayMode {
  normal,
  discrete,
  hidden,
}

enum NotificationMode {
  visible,
  minimized,
  hidden,
}