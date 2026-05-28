import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monitored_app/app/routes.dart';
import 'package:monitored_app/app/theme.dart';
import 'package:monitored_app/app/locator.dart';
import 'package:monitored_app/core/services/auth_service.dart';
import 'package:monitored_app/core/services/background_service.dart';
import 'package:monitored_app/core/services/websocket_service.dart';
import 'package:monitored_app/core/services/data_collector_service.dart';
import 'package:monitored_app/core/services/collection_ownership_service.dart';
import 'package:monitored_app/core/services/battery_monitor_service.dart';
import 'package:monitored_app/core/services/connectivity_service.dart';
import 'package:monitored_app/core/services/database_service.dart';
import 'package:monitored_app/core/services/device_service.dart';
import 'package:monitored_app/core/collectors/sms_collector.dart';
import 'package:monitored_app/core/collectors/calls_collector.dart';
import 'package:monitored_app/core/collectors/location_collector.dart';
import 'package:monitored_app/core/collectors/apps_collector.dart';
import 'package:monitored_app/core/collectors/media_collector.dart';
import 'package:monitored_app/generated/l10n/app_localizations.dart';
import 'dart:async';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  // Services
  final AuthService _authService = locator<AuthService>();
  final BackgroundService _backgroundService = locator<BackgroundService>();
  final WebSocketService _webSocketService = locator<WebSocketService>();
  final DataCollectorService _dataCollectorService =
      locator<DataCollectorService>();
  final BatteryMonitorService _batteryMonitorService =
      locator<BatteryMonitorService>();
  final ConnectivityService _connectivityService =
      locator<ConnectivityService>();
  final DatabaseService _databaseService = locator<DatabaseService>();

  // Collectors
  final SmsCollector _smsCollector = SmsCollector();
  final CallsCollector _callsCollector = CallsCollector();
  final LocationCollector _locationCollector = LocationCollector();
  final AppsCollector _appsCollector = AppsCollector();
  final MediaCollector _mediaCollector = MediaCollector();

  // State variables
  bool _isConnected = false;
  bool _isBackgroundServiceRunning = false;
  String _monitoringDeviceName = "Unknown Device";
  int _batteryLevel = 0;
  NetworkStatus _networkStatus = NetworkStatus.offline;

  // Real monitoring feature status
  Map<String, bool> _featureStatus = {
    'location': false,
    'messages': false,
    'calls': false,
    'apps': false,
    'photos': false,
  };

  // Data statistics
  Map<String, int> _dataStats = {
    'pending_sync_items': 0,
    'total_records': 0,
    'sms_count': 0,
    'calls_count': 0,
    'location_count': 0,
    'apps_count': 0,
  };

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _quickCheckConnectionState(); // fast: local storage only, eliminates initial flash
    _loadRealTimeData();
    _ensureCollectorsRunning(); // Fallback if background service didn't start

    // Refresh data every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadRealTimeData();
    });
  }

  /// Fallback: ensure collectors are running
  /// Used if background service failed to start them
  Future<void> _ensureCollectorsRunning() async {
    try {
      if (!_dataCollectorService.isRunning) {
        debugPrint('[MainScreen] Fallback: starting collectors');
        await _dataCollectorService.startCollectors(
          owner: CollectionLeaseOwner.mainIsolate,
        );
      }
    } catch (e) {
      debugPrint('[MainScreen] Fallback failed: $e');
    }
  }

  /// Fast pre-check using secure storage only (no API / DB calls, ~50 ms).
  /// Eliminates the initial "Déconnecté" flash when the device has a valid session.
  Future<void> _quickCheckConnectionState() async {
    try {
      final hasSession = await _authService.hasValidStoredSession();
      final deviceId = await locator<DeviceService>().getServerDeviceId();
      if (mounted && hasSession && deviceId != null) {
        setState(() => _isConnected = true);
      }
    } catch (_) {
      // Ignore — _loadRealTimeData will set the authoritative state
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadRealTimeData() async {
    // Chaque appel est isolé pour qu'une erreur individuelle n'empêche pas
    // le reste de s'exécuter ni setState d'être appelé.
    bool isServiceRunning = _isBackgroundServiceRunning;
    bool hasValidSession = false;
    String? serverDeviceId;
    int batteryLevel = _batteryLevel;
    NetworkStatus networkStatus = _networkStatus;
    Map<String, dynamic> dbStats = {};
    List<dynamic> pendingSyncItems = [];

    try {
      isServiceRunning = await _backgroundService.isServiceRunning();
    } catch (e) {
      debugPrint('Error checking background service: $e');
    }
    try {
      hasValidSession = await _authService.hasValidStoredSession();
    } catch (e) {
      debugPrint('Error checking session: $e');
    }
    try {
      serverDeviceId = await locator<DeviceService>().getServerDeviceId();
    } catch (e) {
      debugPrint('Error getting server device ID: $e');
    }
    try {
      batteryLevel = await _batteryMonitorService.getCurrentBatteryLevel();
    } catch (e) {
      debugPrint('Error getting battery level: $e');
    }
    try {
      networkStatus = await _connectivityService.checkConnectivity();
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
    }
    try {
      dbStats = await _databaseService.getStatistics();
    } catch (e) {
      debugPrint('Error getting DB statistics: $e');
    }
    try {
      pendingSyncItems = await _databaseService.getPendingSyncItems();
    } catch (e) {
      debugPrint('Error getting pending sync items: $e');
    }

    final isConnected = _webSocketService.isConnected ||
        (hasValidSession && serverDeviceId != null);

    // Load collector status (synchronous)
    final collectorStats = {
      'sms': _smsCollector.getStatistics(),
      'calls': _callsCollector.getStatistics(),
      'location': _locationCollector.getStatistics(),
      'apps': _appsCollector.getStatistics(),
      'media': _mediaCollector.getStatistics(),
    };

    if (mounted) {
      setState(() {
        _isBackgroundServiceRunning = isServiceRunning;
        _isConnected = isConnected;
        _batteryLevel = batteryLevel;
        _networkStatus = networkStatus;

        // Update feature status based on collectors
        _featureStatus = {
          'location': collectorStats['location']?['is_collecting'] ?? false,
          'messages': collectorStats['sms']?['is_collecting'] ?? false,
          'calls': collectorStats['calls']?['is_collecting'] ?? false,
          'apps': collectorStats['apps']?['is_collecting'] ?? false,
          'photos': collectorStats['media']?['is_collecting'] ?? false,
        };

        // Update data statistics
        _dataStats = {
          'pending_sync_items': pendingSyncItems.length,
          'total_records': dbStats['total_records'] ?? 0,
          'sms_count': dbStats['sms'] ?? 0,
          'calls_count': dbStats['calls'] ?? 0,
          'location_count': dbStats['location'] ?? 0,
          'apps_count': dbStats['app_usage'] ?? 0,
        };

        // Update monitoring device name based on connection
        _monitoringDeviceName = isConnected ? "Parent Device" : "Disconnected";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appName),
        automaticallyImplyLeading: false,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'settings') {
                Navigator.pushNamed(context, '/settings');
              } else if (value == 'stealth') {
                Navigator.pushNamed(context, AppRoutes.stealthSettings);
              } else if (value == 'security') {
                Navigator.pushNamed(context, AppRoutes.securitySettings);
              } else if (value == 'media') {
                Navigator.pushNamed(context, AppRoutes.mediaSettings);
              } else if (value == 'refresh') {
                _loadRealTimeData();
              } else if (value == 'exit') {
                _handleLogout();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'refresh',
                child: ListTile(
                  leading: const Icon(Icons.refresh),
                  title: Text('Refresh'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: const Icon(Icons.settings),
                  title: Text(l10n.settings),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'stealth',
                child: ListTile(
                  leading: const Icon(Icons.visibility_off),
                  title: const Text('Stealth Mode'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'security',
                child: ListTile(
                  leading: const Icon(Icons.security),
                  title: const Text('Security'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'media',
                child: ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Media Settings'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'exit',
                child: ListTile(
                  leading: const Icon(Icons.exit_to_app),
                  title: Text(l10n.exit),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              // Connection status card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: _isConnected
                                  ? AppTheme.secondaryColor.withOpacity(0.1)
                                  : AppTheme.alertColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isConnected
                                  ? Icons.check_circle
                                  : Icons.error_outline,
                              color: _isConnected
                                  ? AppTheme.secondaryColor
                                  : AppTheme.alertColor,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isConnected
                                      ? l10n.connected
                                      : l10n.disconnected,
                                  style: Theme.of(context)
                                      .textTheme
                                      .displaySmall
                                      ?.copyWith(
                                        color: _isConnected
                                            ? AppTheme.secondaryColor
                                            : AppTheme.alertColor,
                                      ),
                                ),
                                Text(
                                  _isConnected
                                      ? l10n.connectedToDevice(
                                          _monitoringDeviceName)
                                      : l10n.notConnectedToAnyDevice,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Service: ${_isBackgroundServiceRunning ? "Running" : "Stopped"} • '
                                  'Battery: $_batteryLevel% • '
                                  'Network: ${_networkStatus.name}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Data Statistics Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Data Statistics',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatItem('Total Records',
                              _dataStats['total_records'].toString()),
                          _buildStatItem('Pending Sync',
                              _dataStats['pending_sync_items'].toString()),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatItem(
                              'SMS', _dataStats['sms_count'].toString()),
                          _buildStatItem(
                              'Calls', _dataStats['calls_count'].toString()),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatItem('Locations',
                              _dataStats['location_count'].toString()),
                          _buildStatItem(
                              'Apps', _dataStats['apps_count'].toString()),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Features status
              Text(
                l10n.monitoringStatus,
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 8),

              Card(
                child: ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildFeatureStatusItem(
                      context,
                      'location',
                      Icons.location_on,
                      l10n.locationTracking,
                      _featureStatus['location'] ?? false,
                    ),
                    const Divider(height: 1),
                    _buildFeatureStatusItem(
                      context,
                      'messages',
                      Icons.message,
                      l10n.messageMonitoring,
                      _featureStatus['messages'] ?? false,
                    ),
                    const Divider(height: 1),
                    _buildFeatureStatusItem(
                      context,
                      'calls',
                      Icons.call,
                      l10n.callsMonitoring,
                      _featureStatus['calls'] ?? false,
                    ),
                    const Divider(height: 1),
                    _buildFeatureStatusItem(
                      context,
                      'apps',
                      Icons.apps,
                      l10n.appsMonitoring,
                      _featureStatus['apps'] ?? false,
                    ),
                    const Divider(height: 1),
                    _buildFeatureStatusItem(
                      context,
                      'photos',
                      Icons.photo_library,
                      l10n.photosAccess,
                      _featureStatus['photos'] ?? false,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Quick actions
              Text(
                l10n.quickActions,
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildQuickActionButton(
                    context,
                    Icons.visibility,
                    l10n.viewSharedData,
                    () => Navigator.pushNamed(context, AppRoutes.sharedData),
                  ),
                  _buildQuickActionButton(
                    context,
                    Icons.message,
                    l10n.contactMonitor,
                    () {
                      // TODO: Implement contact monitoring device
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.featureComingSoon)),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Emergency button
              Center(
                child: GestureDetector(
                  onLongPress: () {
                    Navigator.pushNamed(context, AppRoutes.emergency);
                  },
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: AppTheme.emergencyColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.emergencyColor,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.emergency,
                          color: AppTheme.emergencyColor,
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.holdForEmergency,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppTheme.emergencyColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureStatusItem(BuildContext context, String featureKey,
      IconData icon, String title, bool isActive) {
    return ListTile(
      leading: Icon(
        icon,
        color: isActive ? AppTheme.primaryColor : Colors.grey,
      ),
      title: Text(title),
      trailing: isActive
          ? const Icon(Icons.check_circle, color: AppTheme.secondaryColor)
          : const Icon(Icons.cancel, color: Colors.grey),
      onTap: () {
        // Show detailed information about the feature
        _showFeatureDetails(context, featureKey, title, isActive);
      },
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryColor),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  void _showFeatureDetails(
      BuildContext context, String featureKey, String title, bool isActive) {
    String details = '';
    Map<String, dynamic>? stats;

    switch (featureKey) {
      case 'location':
        stats = _locationCollector.getStatistics();
        details = isActive
            ? 'Location tracking is active.\nInterval: ${stats['collection_interval_seconds']}s\nCached items: ${stats['cached_items']}'
            : 'Location tracking is not active. Check permissions or service status.';
        break;
      case 'messages':
        stats = _smsCollector.getStatistics();
        details = isActive
            ? 'SMS monitoring is active.\nCached items: ${stats['cached_items']}'
            : 'SMS monitoring is not active. Check permissions or service status.';
        break;
      case 'calls':
        stats = _callsCollector.getStatistics();
        details = isActive
            ? 'Call monitoring is active.\nCached items: ${stats['cached_items']}'
            : 'Call monitoring is not active. Check permissions or service status.';
        break;
      case 'apps':
        stats = _appsCollector.getStatistics();
        details = isActive
            ? 'App usage monitoring is active.\nCached items: ${stats['cached_items']}'
            : 'App usage monitoring is not active. Check permissions or service status.';
        break;
      case 'photos':
        stats = _mediaCollector.getStatistics();
        details = isActive
            ? 'Media monitoring is active.\nCached items: ${stats['cached_items']}'
            : 'Media monitoring is not active. Check permissions or service status.';
        break;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(details),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
          if (!isActive)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, '/settings');
              },
              child: Text('Settings'),
            ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    final l10n = AppLocalizations.of(context)!;

    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.logoutConfirmation),
        content: Text(l10n.logoutConfirmationMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      try {
        debugPrint('Starting logout process...');

        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        // Stop all background services
        await _backgroundService.stopService();
        await _webSocketService.disconnect();
        await _dataCollectorService.stopCollectors();

        // Clear all data and sign out
        await _authService.signOut();

        debugPrint('Logout completed successfully');

        // Navigate to pairing screen and clear the stack
        if (mounted) {
          Navigator.of(context).pop(); // Dismiss loading dialog
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.welcome,
            (route) => false,
          );
        }
      } catch (e) {
        debugPrint('Error during logout: $e');

        if (mounted) {
          Navigator.of(context).pop(); // Dismiss loading dialog

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la déconnexion: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }
}
