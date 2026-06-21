import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:monitored_app/app/locator.dart';
import 'package:monitored_app/core/services/stealth_service.dart';
import 'package:monitored_app/features/disguise/disguise_manager.dart';
import 'package:monitored_app/features/home/main_screen.dart';

class StealthAppWrapper extends StatefulWidget {
  const StealthAppWrapper({super.key});

  @override
  State<StealthAppWrapper> createState() => _StealthAppWrapperState();
}

class _StealthAppWrapperState extends State<StealthAppWrapper> with WidgetsBindingObserver {
  late StealthService _stealthService;
  StealthConfiguration _currentConfig = const StealthConfiguration();
  StreamSubscription<StealthConfiguration>? _configSubscription;
  bool _isInitialized = false;
  
  // Secret access pattern for entering the real app from disguise
  final List<String> _secretPattern = ['tap', 'tap', 'hold', 'tap'];
  List<String> _currentPattern = [];
  Timer? _patternTimer;
  static const Duration _patternTimeout = Duration(seconds: 5);
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeStealthService();
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _configSubscription?.cancel();
    _patternTimer?.cancel();
    super.dispose();
  }
  
  Future<void> _initializeStealthService() async {
    try {
      _stealthService = locator<StealthService>();
      _currentConfig = _stealthService.currentConfig;
      
      _configSubscription = _stealthService.configStream.listen((config) {
        if (mounted) {
          setState(() {
            _currentConfig = config;
          });
          _applyStealthSettings(config);
        }
      });
      
      setState(() {
        _isInitialized = true;
      });
      
      // Apply initial stealth settings
      _applyStealthSettings(_currentConfig);
    } catch (e) {
      debugPrint('Error initializing stealth service: $e');
      setState(() {
        _isInitialized = true;
      });
    }
  }
  
  void _applyStealthSettings(StealthConfiguration config) {
    // Apply system-level stealth settings
    if (config.disableScreenshots) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    
    // Hide from recent apps (this is typically handled at the native level)
    if (config.hideFromRecents) {
      _hideFromRecents();
    }
  }
  
  void _hideFromRecents() {
    // This would be implemented at the native level
    // For now, we'll just log the intent
    debugPrint('Hiding app from recent apps list');
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Clear pattern when app is backgrounded
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _clearPattern();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // Show disguise UI if stealth mode is active
    if (_currentConfig.mode != StealthMode.none && 
        _currentConfig.disguiseType != DisguiseType.none) {
      return _buildDisguiseWrapper();
    }
    
    // Show normal app
    return const MainScreen();
  }
  
  Widget _buildDisguiseWrapper() {
    final disguiseWidget = DisguiseManager.getDisguiseWidget(_currentConfig.disguiseType);
    
    return GestureDetector(
      onTap: () => _handleSecretTap('tap'),
      onLongPress: () => _handleSecretTap('hold'),
      child: Stack(
        children: [
          disguiseWidget,
          // Invisible overlay for secret access
          if (_currentConfig.mode == StealthMode.full || 
              _currentConfig.mode == StealthMode.invisible)
            _buildSecretAccessOverlay(),
        ],
      ),
    );
  }
  
  Widget _buildSecretAccessOverlay() {
    return Positioned(
      top: 0,
      right: 0,
      child: Container(
        width: 50,
        height: 50,
        color: Colors.transparent,
        child: GestureDetector(
          onTap: () => _handleSecretTap('tap'),
          onLongPress: () => _handleSecretTap('hold'),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.transparent,
                width: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  void _handleSecretTap(String tapType) {
    _currentPattern.add(tapType);
    
    // Reset timer
    _patternTimer?.cancel();
    _patternTimer = Timer(_patternTimeout, _clearPattern);
    
    // Check if pattern matches
    if (_currentPattern.length >= _secretPattern.length) {
      if (_patternMatches()) {
        _showAccessDialog();
      }
      _clearPattern();
    }
  }
  
  bool _patternMatches() {
    if (_currentPattern.length != _secretPattern.length) return false;
    
    for (int i = 0; i < _secretPattern.length; i++) {
      if (_currentPattern[i] != _secretPattern[i]) return false;
    }
    
    return true;
  }
  
  void _clearPattern() {
    _currentPattern.clear();
    _patternTimer?.cancel();
  }
  
  void _showAccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Access Control'),
        content: const Text('Enter PIN to access main application:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showMainApp();
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
  
  void _showMainApp() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const MainScreen(),
      ),
    );
  }
  
}