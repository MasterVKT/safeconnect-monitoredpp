import 'dart:async';
import 'package:flutter/material.dart';
import 'package:monitored_app/app/theme.dart';
import 'package:monitored_app/app/locator.dart';
import 'package:monitored_app/core/services/stealth_service.dart';

class StealthSettingsScreen extends StatefulWidget {
  const StealthSettingsScreen({super.key});

  @override
  State<StealthSettingsScreen> createState() => _StealthSettingsScreenState();
}

class _StealthSettingsScreenState extends State<StealthSettingsScreen> {
  late StealthService _stealthService;
  StealthConfiguration _currentConfig = const StealthConfiguration();
  Map<String, dynamic> _disguiseOptions = {};
  bool _isLoading = false;
  StreamSubscription<StealthConfiguration>? _configSubscription;
  
  // Form controllers
  final TextEditingController _customNameController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _stealthService = locator<StealthService>();
    _currentConfig = _stealthService.currentConfig;
    _customNameController.text = _currentConfig.customAppName ?? '';
    
    _configSubscription = _stealthService.configStream.listen((config) {
      if (mounted) {
        setState(() {
          _currentConfig = config;
          _customNameController.text = config.customAppName ?? '';
        });
      }
    });
    
    _loadDisguiseOptions();
  }
  
  @override
  void dispose() {
    _configSubscription?.cancel();
    _customNameController.dispose();
    super.dispose();
  }
  
  Future<void> _loadDisguiseOptions() async {
    final options = await _stealthService.getDisguiseOptions();
    setState(() {
      _disguiseOptions = options;
    });
  }
  
  Future<void> _updateConfiguration(StealthConfiguration newConfig) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final success = await _stealthService.updateStealthConfiguration(newConfig);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success 
              ? 'Stealth configuration updated'
              : 'Failed to update stealth configuration'),
            backgroundColor: success 
              ? AppTheme.secondaryColor 
              : AppTheme.alertColor,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.alertColor,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _activateQuickStealth() async {
    final success = await _stealthService.enableQuickStealth(
      duration: const Duration(hours: 1),
    );
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success 
            ? 'Quick stealth activated for 1 hour'
            : 'Failed to activate quick stealth'),
          backgroundColor: success 
            ? AppTheme.secondaryColor 
            : AppTheme.alertColor,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stealth & Disguise'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          if (_currentConfig.mode != StealthMode.none)
            IconButton(
              icon: const Icon(Icons.visibility_off),
              onPressed: () async {
                await _stealthService.deactivateStealthMode();
              },
              tooltip: 'Disable Stealth',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCurrentStatus(),
                  const SizedBox(height: 24),
                  _buildQuickActions(),
                  const SizedBox(height: 24),
                  _buildStealthModeSection(),
                  const SizedBox(height: 24),
                  _buildDisguiseSection(),
                  const SizedBox(height: 24),
                  _buildAdvancedOptions(),
                ],
              ),
            ),
    );
  }
  
  Widget _buildCurrentStatus() {
    final isActive = _currentConfig.mode != StealthMode.none;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isActive ? Icons.visibility_off : Icons.visibility,
                  color: isActive ? AppTheme.alertColor : AppTheme.secondaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Current Status',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isActive 
                ? 'Stealth Mode: ${_currentConfig.mode.name.toUpperCase()}'
                : 'Stealth Mode: INACTIVE',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isActive ? AppTheme.alertColor : AppTheme.textColor,
              ),
            ),
            if (isActive && _currentConfig.disguiseType != DisguiseType.none) ...[
              const SizedBox(height: 4),
              Text(
                'Disguise: ${_currentConfig.disguiseType.name}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _activateQuickStealth,
                    icon: const Icon(Icons.flash_on),
                    label: const Text('Quick Stealth'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _currentConfig.mode != StealthMode.none
                        ? () => _stealthService.deactivateStealthMode()
                        : null,
                    icon: const Icon(Icons.visibility),
                    label: const Text('Disable All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.alertColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStealthModeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stealth Mode',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...StealthMode.values.map((mode) => _buildStealthModeOption(mode)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStealthModeOption(StealthMode mode) {
    return RadioListTile<StealthMode>(
      title: Text(_getStealthModeTitle(mode)),
      subtitle: Text(_getStealthModeDescription(mode)),
      value: mode,
      groupValue: _currentConfig.mode,
      onChanged: (value) {
        if (value != null) {
          final newConfig = StealthConfiguration(
            mode: value,
            disguiseType: _currentConfig.disguiseType,
            customAppName: _currentConfig.customAppName,
            customIcon: _currentConfig.customIcon,
            hideFromRecents: _currentConfig.hideFromRecents,
            hideNotifications: _currentConfig.hideNotifications,
            disableScreenshots: _currentConfig.disableScreenshots,
            enableIncognito: _currentConfig.enableIncognito,
            customSettings: _currentConfig.customSettings,
          );
          _updateConfiguration(newConfig);
        }
      },
    );
  }
  
  String _getStealthModeTitle(StealthMode mode) {
    switch (mode) {
      case StealthMode.none:
        return 'Normal';
      case StealthMode.minimal:
        return 'Minimal Stealth';
      case StealthMode.moderate:
        return 'Moderate Stealth';
      case StealthMode.full:
        return 'Full Stealth';
      case StealthMode.invisible:
        return 'Invisible Mode';
    }
  }
  
  String _getStealthModeDescription(StealthMode mode) {
    switch (mode) {
      case StealthMode.none:
        return 'Normal operation, no stealth features';
      case StealthMode.minimal:
        return 'Hide notifications only';
      case StealthMode.moderate:
        return 'Hide app icon and notifications';
      case StealthMode.full:
        return 'Full stealth with disguise';
      case StealthMode.invisible:
        return 'Maximum stealth - completely hidden';
    }
  }
  
  Widget _buildDisguiseSection() {
    if (_currentConfig.mode == StealthMode.none || 
        _currentConfig.mode == StealthMode.minimal) {
      return const SizedBox.shrink();
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Disguise Type',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...DisguiseType.values.map((type) => _buildDisguiseOption(type)),
            if (_currentConfig.disguiseType == DisguiseType.custom) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _customNameController,
                decoration: const InputDecoration(
                  labelText: 'Custom App Name',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  final newConfig = StealthConfiguration(
                    mode: _currentConfig.mode,
                    disguiseType: _currentConfig.disguiseType,
                    customAppName: value.isNotEmpty ? value : null,
                    customIcon: _currentConfig.customIcon,
                    hideFromRecents: _currentConfig.hideFromRecents,
                    hideNotifications: _currentConfig.hideNotifications,
                    disableScreenshots: _currentConfig.disableScreenshots,
                    enableIncognito: _currentConfig.enableIncognito,
                    customSettings: _currentConfig.customSettings,
                  );
                  _updateConfiguration(newConfig);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildDisguiseOption(DisguiseType type) {
    final option = _disguiseOptions[type.name];
    
    return RadioListTile<DisguiseType>(
      title: Text(option?['name'] ?? _getDisguiseTypeTitle(type)),
      subtitle: Text(option?['description'] ?? _getDisguiseTypeDescription(type)),
      value: type,
      groupValue: _currentConfig.disguiseType,
      onChanged: (value) {
        if (value != null) {
          final newConfig = StealthConfiguration(
            mode: _currentConfig.mode,
            disguiseType: value,
            customAppName: value == DisguiseType.custom 
                ? _customNameController.text.isNotEmpty 
                    ? _customNameController.text 
                    : null
                : null,
            customIcon: _currentConfig.customIcon,
            hideFromRecents: _currentConfig.hideFromRecents,
            hideNotifications: _currentConfig.hideNotifications,
            disableScreenshots: _currentConfig.disableScreenshots,
            enableIncognito: _currentConfig.enableIncognito,
            customSettings: _currentConfig.customSettings,
          );
          _updateConfiguration(newConfig);
        }
      },
    );
  }
  
  String _getDisguiseTypeTitle(DisguiseType type) {
    switch (type) {
      case DisguiseType.none:
        return 'No Disguise';
      case DisguiseType.calculator:
        return 'Calculator';
      case DisguiseType.flashlight:
        return 'Flashlight';
      case DisguiseType.weather:
        return 'Weather';
      case DisguiseType.notes:
        return 'Notes';
      case DisguiseType.calendar:
        return 'Calendar';
      case DisguiseType.gameApp:
        return 'Game';
      case DisguiseType.utilityApp:
        return 'Utility';
      case DisguiseType.custom:
        return 'Custom';
    }
  }
  
  String _getDisguiseTypeDescription(DisguiseType type) {
    switch (type) {
      case DisguiseType.none:
        return 'Keep original app appearance';
      case DisguiseType.calculator:
        return 'Appears as a calculator app';
      case DisguiseType.flashlight:
        return 'Appears as a flashlight utility';
      case DisguiseType.weather:
        return 'Appears as a weather app';
      case DisguiseType.notes:
        return 'Appears as a note-taking app';
      case DisguiseType.calendar:
        return 'Appears as a calendar app';
      case DisguiseType.gameApp:
        return 'Appears as a game app';
      case DisguiseType.utilityApp:
        return 'Appears as a utility app';
      case DisguiseType.custom:
        return 'Custom appearance settings';
    }
  }
  
  Widget _buildAdvancedOptions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Advanced Options',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Hide from Recent Apps'),
              subtitle: const Text('Remove app from recent apps list'),
              value: _currentConfig.hideFromRecents,
              onChanged: (value) {
                final newConfig = StealthConfiguration(
                  mode: _currentConfig.mode,
                  disguiseType: _currentConfig.disguiseType,
                  customAppName: _currentConfig.customAppName,
                  customIcon: _currentConfig.customIcon,
                  hideFromRecents: value,
                  hideNotifications: _currentConfig.hideNotifications,
                  disableScreenshots: _currentConfig.disableScreenshots,
                  enableIncognito: _currentConfig.enableIncognito,
                  customSettings: _currentConfig.customSettings,
                );
                _updateConfiguration(newConfig);
              },
            ),
            SwitchListTile(
              title: const Text('Hide Notifications'),
              subtitle: const Text('Suppress all app notifications'),
              value: _currentConfig.hideNotifications,
              onChanged: (value) {
                final newConfig = StealthConfiguration(
                  mode: _currentConfig.mode,
                  disguiseType: _currentConfig.disguiseType,
                  customAppName: _currentConfig.customAppName,
                  customIcon: _currentConfig.customIcon,
                  hideFromRecents: _currentConfig.hideFromRecents,
                  hideNotifications: value,
                  disableScreenshots: _currentConfig.disableScreenshots,
                  enableIncognito: _currentConfig.enableIncognito,
                  customSettings: _currentConfig.customSettings,
                );
                _updateConfiguration(newConfig);
              },
            ),
            SwitchListTile(
              title: const Text('Disable Screenshots'),
              subtitle: const Text('Prevent screenshots and screen recording'),
              value: _currentConfig.disableScreenshots,
              onChanged: (value) {
                final newConfig = StealthConfiguration(
                  mode: _currentConfig.mode,
                  disguiseType: _currentConfig.disguiseType,
                  customAppName: _currentConfig.customAppName,
                  customIcon: _currentConfig.customIcon,
                  hideFromRecents: _currentConfig.hideFromRecents,
                  hideNotifications: _currentConfig.hideNotifications,
                  disableScreenshots: value,
                  enableIncognito: _currentConfig.enableIncognito,
                  customSettings: _currentConfig.customSettings,
                );
                _updateConfiguration(newConfig);
              },
            ),
            SwitchListTile(
              title: const Text('Incognito Mode'),
              subtitle: const Text('Leave minimal traces of operation'),
              value: _currentConfig.enableIncognito,
              onChanged: (value) {
                final newConfig = StealthConfiguration(
                  mode: _currentConfig.mode,
                  disguiseType: _currentConfig.disguiseType,
                  customAppName: _currentConfig.customAppName,
                  customIcon: _currentConfig.customIcon,
                  hideFromRecents: _currentConfig.hideFromRecents,
                  hideNotifications: _currentConfig.hideNotifications,
                  disableScreenshots: _currentConfig.disableScreenshots,
                  enableIncognito: value,
                  customSettings: _currentConfig.customSettings,
                );
                _updateConfiguration(newConfig);
              },
            ),
          ],
        ),
      ),
    );
  }
}