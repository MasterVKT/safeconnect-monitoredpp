import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:monitored_app/app/routes.dart';
import 'package:monitored_app/app/locator.dart';
import 'package:monitored_app/core/services/data_collector_service.dart';
import 'package:monitored_app/features/auth/widgets/progressive_permission_manager.dart';
import 'package:monitored_app/generated/l10n/app_localizations.dart';

class EnhancedPermissionScreen extends ConsumerStatefulWidget {
  const EnhancedPermissionScreen({super.key});

  @override
  ConsumerState<EnhancedPermissionScreen> createState() =>
      _EnhancedPermissionScreenState();
}

class _EnhancedPermissionScreenState
    extends ConsumerState<EnhancedPermissionScreen> {
  Map<String, PermissionStatus> _permissionStatuses = {};
  bool _showSummary = false;
  bool _canProceed = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_showSummary) {
      return _buildSummaryScreen(l10n);
    }

    return ProgressivePermissionManager(
      onPermissionsUpdated: (statuses) {
        setState(() {
          _permissionStatuses = statuses;
          _canProceed = _checkIfCanProceed();
        });
      },
      onAllEssentialGranted: () {
        // Force restart collectors with new permissions
        locator<DataCollectorService>().restartCollectorsAfterPermissionChange();
        setState(() {
          _showSummary = true;
        });
      },
      onCancel: () {
        Navigator.pop(context);
      },
    );
  }

  bool _checkIfCanProceed() {
    // Check if essential permissions are granted
    final essentialPermissions = [
      Permission.location.toString(),
      Permission.phone.toString(),
      Permission.sms.toString(),
      'media_read',
      'accessibility_service',
      'usage_stats',
    ];

    for (final permission in essentialPermissions) {
      final status = _permissionStatuses[permission];
      if (status != PermissionStatus.granted) {
        return false;
      }
    }
    return true;
  }

  Widget _buildSummaryScreen(AppLocalizations l10n) {
    final grantedCount = _permissionStatuses.values
        .where((status) => status == PermissionStatus.granted)
        .length;
    final totalCount = _permissionStatuses.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.permissionSummary),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Success animation/icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: _canProceed
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _canProceed ? Colors.green : Colors.orange,
                  width: 3,
                ),
              ),
              child: Icon(
                _canProceed ? Icons.check_circle : Icons.warning,
                size: 60,
                color: _canProceed ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 24),

            // Summary title
            Text(
              _canProceed
                  ? l10n.permissionsConfigured
                  : l10n.permissionsPartiallyConfigured,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _canProceed ? Colors.green : Colors.orange,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Progress summary
            Text(
              l10n.permissionsGrantedSummary(
                  grantedCount.toString(), totalCount.toString()),
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Permission status list
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.permissionStatusDetails,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _permissionStatuses.length,
                          itemBuilder: (context, index) {
                            final entry =
                                _permissionStatuses.entries.elementAt(index);
                            final isGranted =
                                entry.value == PermissionStatus.granted;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Icon(
                                    isGranted
                                        ? Icons.check_circle
                                        : Icons.error,
                                    color:
                                        isGranted ? Colors.green : Colors.red,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _getPermissionDisplayName(
                                          entry.key, l10n),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ),
                                  Text(
                                    isGranted ? l10n.granted : l10n.notGranted,
                                    style: TextStyle(
                                      color:
                                          isGranted ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Information card
            if (!_canProceed)
              Card(
                color: Colors.orange.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.incompletePermissionsWarning,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.incompletePermissionsDescription,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                if (!_canProceed) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _showSummary = false;
                        });
                      },
                      child: Text(l10n.reviewPermissions),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: ElevatedButton(
                    onPressed: _canProceed
                        ? () => Navigator.pushReplacementNamed(
                            context, AppRoutes.setupComplete)
                        : () => Navigator.pushReplacementNamed(
                            context, AppRoutes.setupComplete),
                    child: Text(_canProceed
                        ? l10n.continueToSetup
                        : l10n.continueAnyway),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getPermissionDisplayName(
      String permissionKey, AppLocalizations l10n) {
    switch (permissionKey) {
      case 'Permission.location':
        return l10n.locationPermission;
      case 'Permission.phone':
        return l10n.phonePermission;
      case 'Permission.sms':
        return l10n.smsPermission;
      case 'Permission.camera':
        return l10n.cameraPermission;
      case 'Permission.microphone':
        return l10n.microphonePermission;
      case 'media_read':
        return l10n.storagePermission;
      case 'Permission.notification':
        return l10n.notificationPermission;
      case 'accessibility_service':
        return l10n.accessibilityPermission;
      case 'usage_stats':
        return l10n.usageStatsPermission;
      case 'device_admin':
        return l10n.deviceAdminPermission;
      case 'battery_optimization':
        return l10n.batteryOptimizationPermission;
      default:
        return permissionKey;
    }
  }
}
