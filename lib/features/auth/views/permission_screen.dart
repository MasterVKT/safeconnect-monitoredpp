import 'package:flutter/material.dart';
import 'package:monitored_app/app/routes.dart';
import 'package:monitored_app/app/theme.dart';
import 'package:monitored_app/core/services/permission_manager_service.dart';
import 'package:monitored_app/generated/l10n/app_localizations.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  int _currentCategoryIndex = 0;
  int _currentPermissionIndex = 0;
  bool _isLoading = false;
  bool _showHelp = false;
  
  final List<PermissionCategory> _categories = [
    PermissionCategory.essential,
    PermissionCategory.monitoring,
    PermissionCategory.media,
    PermissionCategory.system,
  ];
  
  List<PermissionInfo> get _currentCategoryPermissions {
    return PermissionManagerService.getPermissionsByCategory(_categories[_currentCategoryIndex]);
  }
  
  PermissionInfo? get _currentPermission {
    final categoryPermissions = _currentCategoryPermissions;
    if (_currentPermissionIndex < categoryPermissions.length) {
      return categoryPermissions[_currentPermissionIndex];
    }
    return null;
  }
  
  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }
  
  Future<void> _checkPermissions() async {
    setState(() {
      _isLoading = true;
    });
    
    await PermissionManagerService.checkAllPermissions();
    
    setState(() {
      _isLoading = false;
    });
  }
  
  Future<void> _requestCurrentPermission() async {
    final permission = _currentPermission;
    if (permission == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    final granted = await PermissionManagerService.requestPermission(permission);
    
    setState(() {
      _isLoading = false;
    });
    
    if (granted || permission.status == AppPermissionStatus.granted) {
      _goToNextPermission();
    } else if (permission.status == AppPermissionStatus.permanentlyDenied) {
      _showPermanentlyDeniedDialog(permission);
    }
  }
  
  bool _canProceed() {
    return PermissionManagerService.areRequiredPermissionsGranted();
  }
  
  bool _canSkipCurrentPermission() {
    final permission = _currentPermission;
    return permission != null && !permission.isRequired;
  }
  
  void _goToNextPermission() {
    final categoryPermissions = _currentCategoryPermissions;
    
    if (_currentPermissionIndex < categoryPermissions.length - 1) {
      setState(() {
        _currentPermissionIndex++;
      });
    } else {
      _goToNextCategory();
    }
  }
  
  void _goToNextCategory() {
    if (_currentCategoryIndex < _categories.length - 1) {
      setState(() {
        _currentCategoryIndex++;
        _currentPermissionIndex = 0;
      });
    } else {
      _completePermissionSetup();
    }
  }
  
  void _goToPreviousPermission() {
    if (_currentPermissionIndex > 0) {
      setState(() {
        _currentPermissionIndex--;
      });
    } else {
      _goToPreviousCategory();
    }
  }
  
  void _goToPreviousCategory() {
    if (_currentCategoryIndex > 0) {
      setState(() {
        _currentCategoryIndex--;
        final prevCategoryPermissions = PermissionManagerService.getPermissionsByCategory(_categories[_currentCategoryIndex]);
        _currentPermissionIndex = prevCategoryPermissions.length - 1;
      });
    }
  }
  
  void _completePermissionSetup() {
    if (_canProceed()) {
      Navigator.pushReplacementNamed(context, AppRoutes.setupComplete);
    } else {
      _showIncompletePermissionsDialog();
    }
  }
  
  void _showPermanentlyDeniedDialog(PermissionInfo permission) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.permissionDenied),
        content: Text(AppLocalizations.of(context)!.permissionPermanentlyDeniedMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.continueText),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              PermissionManagerService.openAppSettings();
            },
            child: Text(AppLocalizations.of(context)!.openSettings),
          ),
        ],
      ),
    );
  }
  
  void _showIncompletePermissionsDialog() {
    final deniedPermissions = PermissionManagerService.getDeniedRequiredPermissions();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.incompleteSetup),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppLocalizations.of(context)!.requiredPermissionsMissing),
            const SizedBox(height: 16),
            ...deniedPermissions.map((p) => ListTile(
              leading: Icon(Icons.error, color: AppTheme.alertColor),
              title: Text(AppLocalizations.of(context)!.permissionTitle(p.titleKey)),
              dense: true,
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.reviewPermissions),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushReplacementNamed(context, AppRoutes.setupComplete);
            },
            child: Text(AppLocalizations.of(context)!.continueAnyway),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final permission = _currentPermission;
    
    if (_isLoading || permission == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.requiredPermissions),
          automaticallyImplyLeading: false,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    final categoryName = _getCategoryName(_categories[_currentCategoryIndex], l10n);
    final totalPermissions = PermissionManagerService.allPermissions.length;
    final currentPosition = _getCurrentPosition();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.requiredPermissions),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(_showHelp ? Icons.help : Icons.help_outline),
            onPressed: () => setState(() => _showHelp = !_showHelp),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: currentPosition / totalPermissions,
                  backgroundColor: Colors.grey[300],
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$categoryName (${_currentPermissionIndex + 1}/${_currentCategoryPermissions.length})',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '${currentPosition}/${totalPermissions}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Help section
          if (_showHelp)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        l10n.whyDoWeNeedThis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.permissionExplanation(permission.explanationKey),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          
          // Main content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Permission icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: permission.status == AppPermissionStatus.granted
                          ? AppTheme.secondaryColor.withValues(alpha: 0.1)
                          : AppTheme.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getIconData(permission.icon ?? 'help'),
                      size: 60,
                      color: permission.status == AppPermissionStatus.granted
                          ? AppTheme.secondaryColor
                          : AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Permission title
                  Text(
                    l10n.permissionTitle(permission.titleKey),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  
                  // Permission description
                  Text(
                    l10n.permissionDescription(permission.descriptionKey),
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  
                  // Required/Optional badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: permission.isRequired
                          ? AppTheme.alertColor.withValues(alpha: 0.1)
                          : Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      permission.isRequired
                          ? l10n.requiredPermission
                          : l10n.optionalPermission,
                      style: TextStyle(
                        color: permission.isRequired
                            ? AppTheme.alertColor
                            : Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Permission status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        permission.status == AppPermissionStatus.granted
                            ? Icons.check_circle
                            : Icons.warning,
                        color: permission.status == AppPermissionStatus.granted
                            ? AppTheme.secondaryColor
                            : AppTheme.alertColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        permission.status == AppPermissionStatus.granted
                            ? l10n.permissionGranted
                            : l10n.permissionRequired,
                        style: TextStyle(
                          color: permission.status == AppPermissionStatus.granted
                              ? AppTheme.secondaryColor
                              : AppTheme.alertColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom navigation
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Action buttons
                Row(
                  children: [
                    // Back button
                    if (currentPosition > 1)
                      Expanded(
                        child: TextButton(
                          onPressed: _goToPreviousPermission,
                          child: Text(l10n.back),
                        ),
                      ),
                    
                    if (currentPosition > 1) const SizedBox(width: 16),
                    
                    // Main action button
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : (permission.status == AppPermissionStatus.granted
                                ? _goToNextPermission
                                : _requestCurrentPermission),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                permission.status == AppPermissionStatus.granted
                                    ? l10n.continueText
                                    : l10n.grantPermission,
                              ),
                      ),
                    ),
                    
                    // Skip button for optional permissions
                    if (_canSkipCurrentPermission())
                      Expanded(
                        child: TextButton(
                          onPressed: _goToNextPermission,
                          child: Text(l10n.skip),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Complete setup button (shown when all required permissions are granted)
                if (_canProceed())
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.setupComplete),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryColor,
                      ),
                      child: Text(l10n.completeSetup),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  String _getCategoryName(PermissionCategory category, AppLocalizations l10n) {
    switch (category) {
      case PermissionCategory.essential:
        return l10n.essentialPermissions;
      case PermissionCategory.monitoring:
        return l10n.monitoringPermissions;
      case PermissionCategory.media:
        return l10n.mediaPermissions;
      case PermissionCategory.system:
        return l10n.systemPermissions;
    }
  }
  
  int _getCurrentPosition() {
    int position = 0;
    for (int i = 0; i < _currentCategoryIndex; i++) {
      position += PermissionManagerService.getPermissionsByCategory(_categories[i]).length;
    }
    return position + _currentPermissionIndex + 1;
  }
  
  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'location_on':
        return Icons.location_on;
      case 'location_history':
        return Icons.location_history;
      case 'sms':
        return Icons.sms;
      case 'call':
        return Icons.call;
      case 'assessment':
        return Icons.assessment;
      case 'accessibility':
        return Icons.accessibility;
      case 'camera_alt':
        return Icons.camera_alt;
      case 'mic':
        return Icons.mic;
      case 'storage':
        return Icons.storage;
      case 'admin_panel_settings':
        return Icons.admin_panel_settings;
      case 'battery_saver':
        return Icons.battery_saver;
      case 'notifications':
        return Icons.notifications;
      default:
        return Icons.help;
    }
  }
}