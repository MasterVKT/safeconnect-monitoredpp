import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:monitored_app/core/utils/media_permission_utils.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:monitored_app/generated/l10n/app_localizations.dart';

enum PermissionCategory {
  essential, // Must have for basic functionality
  monitoring, // Core monitoring features
  advanced, // Enhanced features
  optional, // Nice to have
}

enum PermissionComplexity {
  simple, // Standard permission dialog
  complex, // Requires settings navigation
  special, // Device admin, accessibility, etc.
}

class PermissionItem {
  final Permission? standardPermission;
  final List<Permission>? standardPermissions;
  final String customPermissionKey; // For non-standard permissions
  final String titleKey;
  final String descriptionKey;
  final String detailedDescriptionKey;
  final IconData icon;
  final PermissionCategory category;
  final PermissionComplexity complexity;
  final bool isRequired;
  final bool isAndroidOnly;
  final bool isIosOnly;
  final List<String> troubleshootingSteps;
  final String? settingsPath;
  PermissionStatus status;

  PermissionItem({
    this.standardPermission,
    this.standardPermissions,
    this.customPermissionKey = '',
    required this.titleKey,
    required this.descriptionKey,
    required this.detailedDescriptionKey,
    required this.icon,
    required this.category,
    required this.complexity,
    required this.isRequired,
    this.isAndroidOnly = false,
    this.isIosOnly = false,
    required this.troubleshootingSteps,
    this.settingsPath,
    this.status = PermissionStatus.denied,
  });
}

class ProgressivePermissionManager extends StatefulWidget {
  final Function(Map<String, PermissionStatus>) onPermissionsUpdated;
  final VoidCallback? onAllEssentialGranted;
  final VoidCallback? onCancel;

  const ProgressivePermissionManager({
    super.key,
    required this.onPermissionsUpdated,
    this.onAllEssentialGranted,
    this.onCancel,
  });

  @override
  State<ProgressivePermissionManager> createState() =>
      _ProgressivePermissionManagerState();
}

class _ProgressivePermissionManagerState
    extends State<ProgressivePermissionManager> with WidgetsBindingObserver {
  int _currentCategoryIndex = 0;
  int _currentPermissionIndex = 0;
  bool _isLoading = false;
  String? _errorMessage;
  bool _showTroubleshooting = false;
  PermissionItem? _pendingPermission;

  static const MethodChannel _channel =
      MethodChannel('monitored_app/permissions');

  final List<List<PermissionItem>> _permissionCategories = [
    // Essential permissions
    [
      PermissionItem(
        standardPermission: Permission.location,
        titleKey: 'locationPermission',
        descriptionKey: 'locationPermissionDescription',
        detailedDescriptionKey: 'locationPermissionDetailed',
        icon: Icons.location_on,
        category: PermissionCategory.essential,
        complexity: PermissionComplexity.simple,
        isRequired: true,
        troubleshootingSteps: [
          'Go to Settings > Apps > XP SafeConnect > Permissions',
          'Enable Location permission',
          'Select "Allow all the time" for background location',
          'Restart the app'
        ],
      ),
      PermissionItem(
        standardPermission: Permission.phone,
        titleKey: 'phonePermission',
        descriptionKey: 'phonePermissionDescription',
        detailedDescriptionKey: 'phonePermissionDetailed',
        icon: Icons.call,
        category: PermissionCategory.essential,
        complexity: PermissionComplexity.simple,
        isRequired: true,
        isAndroidOnly: true,
        troubleshootingSteps: [
          'Go to Settings > Apps > XP SafeConnect > Permissions',
          'Enable Phone permission',
          'Allow both "Make and manage phone calls" and "Read phone state"'
        ],
      ),
    ],
    // Monitoring permissions
    [
      PermissionItem(
        standardPermission: Permission.sms,
        titleKey: 'smsPermission',
        descriptionKey: 'smsPermissionDescription',
        detailedDescriptionKey: 'smsPermissionDetailed',
        icon: Icons.sms,
        category: PermissionCategory.monitoring,
        complexity: PermissionComplexity.simple,
        isRequired: true,
        isAndroidOnly: true,
        troubleshootingSteps: [
          'Go to Settings > Apps > XP SafeConnect > Permissions',
          'Enable SMS permission',
          'Ensure "Send and view SMS messages" is allowed'
        ],
      ),
      PermissionItem(
        standardPermissions: const [
          Permission.photos,
          Permission.videos,
          Permission.audio,
        ],
        customPermissionKey: 'media_read',
        titleKey: 'storagePermission',
        descriptionKey: 'storagePermissionDescription',
        detailedDescriptionKey: 'storagePermissionExplanation',
        icon: Icons.photo_library,
        category: PermissionCategory.monitoring,
        complexity: PermissionComplexity.simple,
        isRequired: true,
        isAndroidOnly: true,
        troubleshootingSteps: [
          'Go to Settings > Apps > XP SafeConnect > Permissions',
          'Enable Photos and videos permission',
          'Enable Music and audio permission',
        ],
      ),
      PermissionItem(
        customPermissionKey: 'accessibility_service',
        titleKey: 'accessibilityPermission',
        descriptionKey: 'accessibilityPermissionDescription',
        detailedDescriptionKey: 'accessibilityPermissionDetailed',
        icon: Icons.accessibility,
        category: PermissionCategory.monitoring,
        complexity: PermissionComplexity.special,
        isRequired: true,
        isAndroidOnly: true,
        troubleshootingSteps: [
          'Go to Settings > Accessibility',
          'Find "XP SafeConnect" in the list',
          'Toggle the switch to enable the service',
          'Confirm by tapping "Allow" in the dialog'
        ],
        settingsPath: 'android.settings.ACCESSIBILITY_SETTINGS',
      ),
      PermissionItem(
        customPermissionKey: 'usage_stats',
        titleKey: 'usageStatsPermission',
        descriptionKey: 'usageStatsPermissionDescription',
        detailedDescriptionKey: 'usageStatsPermissionDetailed',
        icon: Icons.analytics,
        category: PermissionCategory.monitoring,
        complexity: PermissionComplexity.special,
        isRequired: true,
        isAndroidOnly: true,
        troubleshootingSteps: [
          'Go to Settings > Apps > Special access > Usage access',
          'Find "XP SafeConnect" in the list',
          'Toggle the switch to enable usage access',
          'Return to the app'
        ],
        settingsPath: 'android.settings.USAGE_ACCESS_SETTINGS',
      ),
    ],
    // Advanced permissions
    [
      PermissionItem(
        customPermissionKey: 'device_admin',
        titleKey: 'deviceAdminPermission',
        descriptionKey: 'deviceAdminPermissionDescription',
        detailedDescriptionKey: 'deviceAdminPermissionDetailed',
        icon: Icons.admin_panel_settings,
        category: PermissionCategory.advanced,
        complexity: PermissionComplexity.special,
        isRequired: false,
        isAndroidOnly: true,
        troubleshootingSteps: [
          'Go to Settings > Security > Device admin apps',
          'Find "XP SafeConnect" in the list',
          'Toggle the switch to activate device administrator',
          'Read and accept the permissions'
        ],
        settingsPath: 'android.settings.SECURITY_SETTINGS',
      ),
      PermissionItem(
        standardPermission: Permission.camera,
        titleKey: 'cameraPermission',
        descriptionKey: 'cameraPermissionDescription',
        detailedDescriptionKey: 'cameraPermissionDetailed',
        icon: Icons.camera_alt,
        category: PermissionCategory.advanced,
        complexity: PermissionComplexity.simple,
        isRequired: false,
        troubleshootingSteps: [
          'Go to Settings > Apps > XP SafeConnect > Permissions',
          'Enable Camera permission',
          'Allow camera access for remote photo capture'
        ],
      ),
      PermissionItem(
        standardPermission: Permission.microphone,
        titleKey: 'microphonePermission',
        descriptionKey: 'microphonePermissionDescription',
        detailedDescriptionKey: 'microphonePermissionDetailed',
        icon: Icons.mic,
        category: PermissionCategory.advanced,
        complexity: PermissionComplexity.simple,
        isRequired: false,
        troubleshootingSteps: [
          'Go to Settings > Apps > XP SafeConnect > Permissions',
          'Enable Microphone permission',
          'Allow microphone access for remote audio recording'
        ],
      ),
    ],
    // Optional permissions
    [
      PermissionItem(
        standardPermission: Permission.notification,
        titleKey: 'notificationPermission',
        descriptionKey: 'notificationPermissionDescription',
        detailedDescriptionKey: 'notificationPermissionDetailed',
        icon: Icons.notifications,
        category: PermissionCategory.optional,
        complexity: PermissionComplexity.simple,
        isRequired: false,
        troubleshootingSteps: [
          'Go to Settings > Apps > XP SafeConnect > Notifications',
          'Enable "Allow notifications"',
          'Ensure all notification categories are enabled'
        ],
      ),
      PermissionItem(
        customPermissionKey: 'battery_optimization',
        titleKey: 'batteryOptimizationPermission',
        descriptionKey: 'batteryOptimizationPermissionDescription',
        detailedDescriptionKey: 'batteryOptimizationPermissionDetailed',
        icon: Icons.battery_saver,
        category: PermissionCategory.optional,
        complexity: PermissionComplexity.special,
        isRequired: false,
        isAndroidOnly: true,
        troubleshootingSteps: [
          'Go to Settings > Battery > Battery optimization',
          'Find "XP SafeConnect" in the list',
          'Select "Don\'t optimize"',
          'Confirm the selection'
        ],
        settingsPath: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
      ),
    ],
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializePermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _pendingPermission != null) {
      _refreshPendingPermission();
    }
  }

  Future<void> _initializePermissions() async {
    setState(() {
      _isLoading = true;
    });

    // Filter permissions by platform
    for (int categoryIndex = 0;
        categoryIndex < _permissionCategories.length;
        categoryIndex++) {
      _permissionCategories[categoryIndex] =
          _permissionCategories[categoryIndex].where((permission) {
        if (Platform.isAndroid && permission.isIosOnly) return false;
        if (Platform.isIOS && permission.isAndroidOnly) return false;
        return true;
      }).toList();
    }

    await _checkAllPermissions();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _checkAllPermissions() async {
    for (final category in _permissionCategories) {
      for (final permission in category) {
        await _checkPermissionStatus(permission);
      }
    }
    _notifyPermissionUpdates();
  }

  Future<void> _checkPermissionStatus(PermissionItem permission) async {
    try {
      if (permission.standardPermission != null) {
        permission.status = await permission.standardPermission!.status;
      } else if (permission.standardPermissions != null) {
        permission.status = await _aggregateGroupedPermissionStatus(permission);
      } else {
        // Handle custom permissions via method channel
        final status = await _channel.invokeMethod('checkPermission', {
          'permission': permission.customPermissionKey,
        });
        permission.status = _parsePermissionStatus(status);
      }
    } catch (e) {
      permission.status = PermissionStatus.denied;
    }
  }

  PermissionStatus _parsePermissionStatus(dynamic status) {
    switch (status.toString().toLowerCase()) {
      case 'granted':
        return PermissionStatus.granted;
      case 'denied':
        return PermissionStatus.denied;
      case 'restricted':
        return PermissionStatus.restricted;
      case 'limited':
        return PermissionStatus.limited;
      case 'permanentlydenied':
        return PermissionStatus.permanentlyDenied;
      default:
        return PermissionStatus.denied;
    }
  }

  Future<PermissionStatus> _aggregateGroupedPermissionStatus(
    PermissionItem permission,
  ) async {
    if (permission.customPermissionKey == 'media_read') {
      final status = await MediaPermissionUtils.aggregateReadStatus();
      return status.isLimited ? PermissionStatus.granted : status;
    }

    final statuses = <PermissionStatus>[];
    for (final standardPermission
        in permission.standardPermissions ?? const []) {
      statuses.add(await standardPermission.status);
    }

    if (statuses.any((status) => status.isGranted)) {
      return PermissionStatus.granted;
    }
    if (statuses.any((status) => status.isLimited)) {
      return PermissionStatus.limited;
    }
    if (statuses.any((status) => status.isPermanentlyDenied)) {
      return PermissionStatus.permanentlyDenied;
    }
    if (statuses.any((status) => status.isRestricted)) {
      return PermissionStatus.restricted;
    }
    return PermissionStatus.denied;
  }

  void _notifyPermissionUpdates() {
    final Map<String, PermissionStatus> permissionMap = {};
    for (final category in _permissionCategories) {
      for (final permission in category) {
        final key = permission.standardPermission?.toString() ??
            permission.customPermissionKey;
        permissionMap[key] = permission.status;
      }
    }
    widget.onPermissionsUpdated(permissionMap);
  }

  Future<void> _requestCurrentPermission() async {
    final currentCategory = _permissionCategories[_currentCategoryIndex];
    final currentPermission = currentCategory[_currentPermissionIndex];

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (currentPermission.standardPermission != null) {
        final status = await currentPermission.standardPermission!.request();
        currentPermission.status = status;
      } else if (currentPermission.standardPermissions != null) {
        await MediaPermissionUtils.requestReadPermissions();
        currentPermission.status =
            await _aggregateGroupedPermissionStatus(currentPermission);
      } else {
        // Handle custom permissions
        final awaitingUserAction =
            await _requestManualPermission(currentPermission);
        if (awaitingUserAction) {
          return;
        }
      }

      await _checkPermissionStatus(currentPermission);
      _notifyPermissionUpdates();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ignore: unused_element
  Future<void> _requestCustomPermission(PermissionItem permission) async {
    switch (permission.customPermissionKey) {
      case 'accessibility_service':
      case 'usage_stats':
      case 'device_admin':
      case 'battery_optimization':
        // Open relevant settings screen
        if (permission.settingsPath != null) {
          final l10n = AppLocalizations.of(context)!;
          final String stepsText = permission.troubleshootingSteps
              .asMap()
              .entries
              .map((e) => '${e.key + 1}. ${e.value}')
              .join('\n');

          final bool? shouldOpen = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(l10n.openSettings),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.localeName == 'fr'
                      ? 'Pour accorder cette autorisation, vous devez ouvrir les paramètres système. Veuillez suivre ces étapes :'
                      : 'To grant this permission, you need to open system settings. Please follow these steps:'),
                  const SizedBox(height: 16),
                  Text(l10n.troubleshootingSteps,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(stepsText),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(l10n.openSettings),
                ),
              ],
            ),
          );

          if (shouldOpen != true) {
            throw Exception('User cancelled settings navigation');
          }

          await _channel.invokeMethod('openSettings', {
            'settingsPath': permission.settingsPath,
          });
        }
        break;
      default:
        throw Exception(
            'Unknown custom permission: ${permission.customPermissionKey}');
    }
  }

  Future<bool> _requestManualPermission(PermissionItem permission) async {
    final l10n = AppLocalizations.of(context)!;
    final steps = _getLocalizedSteps(permission);
    final bool? shouldOpen = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.openSettings),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getManualPermissionIntro()),
            const SizedBox(height: 16),
            Text(
              l10n.troubleshootingSteps,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...steps.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('${entry.key + 1}. ${entry.value}'),
                  ),
                ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.openSettings),
          ),
        ],
      ),
    );

    if (shouldOpen != true) {
      return false;
    }

    _pendingPermission = permission;
    await _channel.invokeMethod('requestPermission', {
      'permission': permission.customPermissionKey,
      'settingsPath': permission.settingsPath,
    });
    return true;
  }

  Future<void> _refreshPendingPermission() async {
    final pendingPermission = _pendingPermission;
    if (pendingPermission == null || !mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await _checkPermissionStatus(pendingPermission);
    _notifyPermissionUpdates();

    if (!mounted) {
      return;
    }

    final granted = pendingPermission.status == PermissionStatus.granted;

    setState(() {
      _isLoading = false;
      _pendingPermission = null;
      _errorMessage = null;
      if (!granted) {
        _showTroubleshooting = true;
      }
    });

    if (granted &&
        identical(
          pendingPermission,
          _permissionCategories[_currentCategoryIndex][_currentPermissionIndex],
        )) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isFrench()
                ? 'Autorisation detectee automatiquement.'
                : 'Permission detected automatically.',
          ),
        ),
      );
      _goToNextPermission();
    }
  }

  bool _isFrench() => Localizations.localeOf(context).languageCode == 'fr';

  bool _requiresManualSetup(PermissionItem permission) {
    return permission.complexity != PermissionComplexity.simple;
  }

  String _getManualPermissionIntro() {
    return _isFrench()
        ? 'Cette autorisation ne s\'accorde pas dans une fenetre classique. Suivez les etapes ci-dessous dans les parametres, puis revenez ici : l\'application verifiera automatiquement le resultat.'
        : 'This permission is not granted through a standard popup. Follow the steps below in system settings, then return here: the app will verify the result automatically.';
  }

  String _getPrimaryActionLabel(
      PermissionItem permission, AppLocalizations l10n) {
    if (permission.status == PermissionStatus.granted) {
      return l10n.continueText;
    }

    if (_requiresManualSetup(permission)) {
      return l10n.openSettings;
    }

    return l10n.grantPermission;
  }

  List<String> _getLocalizedSteps(PermissionItem permission) {
    if (_isFrench()) {
      switch (permission.customPermissionKey) {
        case 'accessibility_service':
          return const [
            'Ouvrez les parametres d\'accessibilite.',
            'Reperez "XP SafeConnect" dans la liste des services.',
            'Activez le service puis confirmez l\'autorisation demandee.',
            'Revenez dans l\'application : la validation se fera automatiquement.',
          ];
        case 'usage_stats':
          return const [
            'Ouvrez l\'acces d\'utilisation des applications.',
            'Choisissez "XP SafeConnect" dans la liste.',
            'Activez l\'option d\'acces d\'utilisation.',
            'Revenez dans l\'application : la validation se fera automatiquement.',
          ];
        case 'media_read':
          return const [
            'Ouvrez les parametres de permissions de XP SafeConnect.',
            'Autorisez l\'acces aux photos et videos.',
            'Autorisez l\'acces a la musique et a l\'audio.',
            'Si Android propose un acces partiel, selectionnez les medias a partager.',
          ];
        case 'device_admin':
          return const [
            'L\'ecran systeme d\'activation de l\'administrateur va s\'ouvrir.',
            'Verifiez qu\'il s\'agit bien de "XP SafeConnect".',
            'Touchez le bouton pour activer l\'administrateur de l\'appareil.',
            'Revenez ensuite dans l\'application.',
          ];
        case 'battery_optimization':
          return const [
            'L\'ecran systeme d\'optimisation de batterie va s\'ouvrir.',
            'Choisissez l\'option qui autorise XP SafeConnect a fonctionner en arriere-plan.',
            'Confirmez la desactivation de l\'optimisation si Android le demande.',
            'Revenez ensuite dans l\'application.',
          ];
      }
    } else {
      switch (permission.customPermissionKey) {
        case 'accessibility_service':
          return const [
            'Open the accessibility settings screen.',
            'Find "XP SafeConnect" in the list of services.',
            'Turn the service on and confirm the system prompt.',
            'Return to the app: validation will happen automatically.',
          ];
        case 'usage_stats':
          return const [
            'Open the Usage Access settings screen.',
            'Select "XP SafeConnect" from the list.',
            'Allow usage access for the app.',
            'Return to the app: validation will happen automatically.',
          ];
        case 'media_read':
          return const [
            'Open the XP SafeConnect permission settings.',
            'Allow access to photos and videos.',
            'Allow access to music and audio.',
            'If Android offers partial access, select the media to share.',
          ];
        case 'device_admin':
          return const [
            'The system device admin activation screen will open.',
            'Make sure the screen is for "XP SafeConnect".',
            'Tap the button to activate device administrator access.',
            'Then return to the app.',
          ];
        case 'battery_optimization':
          return const [
            'The system battery optimization screen will open.',
            'Choose the option that allows XP SafeConnect to keep running in the background.',
            'Confirm the exclusion if Android asks for it.',
            'Then return to the app.',
          ];
      }
    }

    return permission.troubleshootingSteps;
  }

  void _goToNextPermission() {
    final currentCategory = _permissionCategories[_currentCategoryIndex];

    if (_currentPermissionIndex < currentCategory.length - 1) {
      setState(() {
        _currentPermissionIndex++;
        _showTroubleshooting = false;
      });
    } else if (_currentCategoryIndex < _permissionCategories.length - 1) {
      setState(() {
        _currentCategoryIndex++;
        _currentPermissionIndex = 0;
        _showTroubleshooting = false;
      });
    } else {
      // All categories completed
      _checkIfEssentialGranted();
    }
  }

  void _goToPreviousPermission() {
    if (_currentPermissionIndex > 0) {
      setState(() {
        _currentPermissionIndex--;
        _showTroubleshooting = false;
      });
    } else if (_currentCategoryIndex > 0) {
      setState(() {
        _currentCategoryIndex--;
        _currentPermissionIndex =
            _permissionCategories[_currentCategoryIndex].length - 1;
        _showTroubleshooting = false;
      });
    }
  }

  void _checkIfEssentialGranted() {
    bool allEssentialGranted = true;

    for (final category in _permissionCategories) {
      for (final permission in category) {
        if (permission.category == PermissionCategory.essential &&
            permission.isRequired &&
            permission.status != PermissionStatus.granted) {
          allEssentialGranted = false;
          break;
        }
      }
      if (!allEssentialGranted) break;
    }

    if (allEssentialGranted && widget.onAllEssentialGranted != null) {
      widget.onAllEssentialGranted!();
    }
  }

  String _getCurrentCategoryName(AppLocalizations l10n) {
    switch (_permissionCategories[_currentCategoryIndex].first.category) {
      case PermissionCategory.essential:
        return l10n.essentialPermissions;
      case PermissionCategory.monitoring:
        return l10n.monitoringPermissions;
      case PermissionCategory.advanced:
        return l10n.advancedPermissions;
      case PermissionCategory.optional:
        return l10n.optionalPermissions;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                l10n.checkingPermissions,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    if (_permissionCategories.isEmpty ||
        _currentCategoryIndex >= _permissionCategories.length ||
        _permissionCategories[_currentCategoryIndex].isEmpty ||
        _currentPermissionIndex >=
            _permissionCategories[_currentCategoryIndex].length) {
      return Scaffold(
        body: Center(
          child: Text(l10n.noPermissionsToRequest),
        ),
      );
    }

    final currentCategory = _permissionCategories[_currentCategoryIndex];
    final currentPermission = currentCategory[_currentPermissionIndex];
    final totalPermissions =
        _permissionCategories.expand((category) => category).length;
    final currentOverallIndex = _permissionCategories
            .take(_currentCategoryIndex)
            .expand((category) => category)
            .length +
        _currentPermissionIndex;
    final localizedSteps = _getLocalizedSteps(currentPermission);

    return Scaffold(
      appBar: AppBar(
        title: Text(_getCurrentCategoryName(l10n)),
        automaticallyImplyLeading: false,
        actions: [
          if (widget.onCancel != null)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: widget.onCancel,
            ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (currentOverallIndex + 1) / totalPermissions,
            backgroundColor: Colors.grey[300],
            color: Theme.of(context).primaryColor,
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Permission step indicator
                  Text(
                    l10n.permissionStep((currentOverallIndex + 1).toString(),
                        totalPermissions.toString()),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 24),

                  // Permission icon and status
                  Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color:
                            currentPermission.status == PermissionStatus.granted
                                ? Colors.green.withValues(alpha: 0.1)
                                : Theme.of(context)
                                    .primaryColor
                                    .withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: currentPermission.status ==
                                  PermissionStatus.granted
                              ? Colors.green
                              : Theme.of(context).primaryColor,
                          width: 2,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            currentPermission.icon,
                            size: 60,
                            color: currentPermission.status ==
                                    PermissionStatus.granted
                                ? Colors.green
                                : Theme.of(context).primaryColor,
                          ),
                          if (currentPermission.status ==
                              PermissionStatus.granted)
                            Positioned(
                              right: 8,
                              bottom: 8,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Permission title
                  Text(
                    l10n.permissionTitle(currentPermission.titleKey),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Permission description
                  Text(
                    l10n.permissionDescription(
                        currentPermission.descriptionKey),
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Detailed description
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n.whyThisPermission,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.permissionDescription(
                                currentPermission.detailedDescriptionKey),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          if (currentPermission.isRequired) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color:
                                        Colors.orange.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.warning_amber,
                                      color: Colors.orange, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      l10n.requiredPermissionWarning,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Colors.orange[800],
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  if (_requiresManualSetup(currentPermission)) ...[
                    const SizedBox(height: 16),
                    Card(
                      color: Theme.of(context)
                          .primaryColor
                          .withValues(alpha: 0.05),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.route,
                                  color: Theme.of(context).primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.troubleshootingSteps,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _getManualPermissionIntro(),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 12),
                            ...localizedSteps.asMap().entries.map((entry) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${entry.key + 1}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        entry.value,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Error message
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Troubleshooting section
                  if (_showTroubleshooting &&
                      !_requiresManualSetup(currentPermission)) ...[
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.help_outline,
                                  color: Theme.of(context).primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.troubleshootingSteps,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...localizedSteps.asMap().entries.map((entry) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${entry.key + 1}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        entry.value,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 100), // Space for floating buttons
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Back button
                if (_currentCategoryIndex > 0 || _currentPermissionIndex > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _goToPreviousPermission,
                      child: Text(l10n.back),
                    ),
                  ),

                if (_currentCategoryIndex > 0 || _currentPermissionIndex > 0)
                  const SizedBox(width: 16),

                // Main action button
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed:
                        currentPermission.status == PermissionStatus.granted
                            ? _goToNextPermission
                            : _requestCurrentPermission,
                    child:
                        Text(_getPrimaryActionLabel(currentPermission, l10n)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Helper buttons
            Row(
              children: [
                if (currentPermission.status != PermissionStatus.granted) ...[
                  if (!_requiresManualSetup(currentPermission)) ...[
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => setState(() {
                          _showTroubleshooting = !_showTroubleshooting;
                        }),
                        icon: Icon(
                          _showTroubleshooting
                              ? Icons.expand_less
                              : Icons.help_outline,
                        ),
                        label: Text(
                          _showTroubleshooting
                              ? l10n.hideTroubleshooting
                              : l10n.needHelp,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: TextButton.icon(
                      onPressed: !currentPermission.isRequired
                          ? _goToNextPermission
                          : null,
                      icon: const Icon(Icons.skip_next),
                      label: Text(l10n.skipOptional),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
