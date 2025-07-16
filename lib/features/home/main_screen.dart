import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monitored_app/app/routes.dart';
import 'package:monitored_app/app/theme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  final bool _isConnected = true;
  final String _monitoringDeviceName = "Dispositif Parent";
  bool _emergencyModeEnabled = false;
  
  // Sample statuses for the monitoring features
  final Map<String, bool> _featureStatus = {
    'location': true,
    'messages': true,
    'calls': true,
    'apps': true,
    'photos': false,
  };

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
                // TODO: Open settings
              } else if (value == 'exit') {
                // TODO: Handle logout
              }
            },
            itemBuilder: (context) => [
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                              _isConnected ? Icons.check_circle : Icons.error_outline,
                              color: _isConnected ? AppTheme.secondaryColor : AppTheme.alertColor,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isConnected ? l10n.connected : l10n.disconnected,
                                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                    color: _isConnected ? AppTheme.secondaryColor : AppTheme.alertColor,
                                  ),
                                ),
                                Text(
                                  _isConnected 
                                      ? l10n.connectedToDevice(_monitoringDeviceName)
                                      : l10n.notConnectedToAnyDevice,
                                  style: Theme.of(context).textTheme.bodyMedium,
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
              
              const SizedBox(height: 24),
              
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
              
              const Spacer(),
              
              // Emergency button
              Center(
                child: GestureDetector(
                  onLongPress: () {
                    setState(() {
                      _emergencyModeEnabled = true;
                    });
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
  
  Widget _buildFeatureStatusItem(
    BuildContext context, 
    String featureKey, 
    IconData icon, 
    String title, 
    bool isActive
  ) {
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
        // TODO: Maybe show more details about this feature
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isActive 
                  ? l10n.featureActiveAndSharing(title)
                  : l10n.featureNotActive(title),
            ),
          ),
        );
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
}