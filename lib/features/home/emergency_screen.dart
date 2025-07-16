import 'dart:async';

import 'package:flutter/material.dart';
import 'package:monitored_app/app/theme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  
  bool _emergencyActivated = false;
  bool _isLoading = false;
  
  // Countdown for emergency activation
  int _countdownSeconds = 5;
  Timer? _countdownTimer;
  
  @override
  void initState() {
    super.initState();
    
    // Setup the pulse animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _animationController.repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }
  
  void _startEmergencyMode() {
    setState(() {
      _countdownSeconds = 5;
      _isLoading = true;
    });
    
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_countdownSeconds > 0) {
          _countdownSeconds--;
        } else {
          _activateEmergency();
          timer.cancel();
        }
      });
    });
  }
  
  void _cancelEmergency() {
    _countdownTimer?.cancel();
    setState(() {
      _isLoading = false;
      _emergencyActivated = false;
      _countdownSeconds = 5;
    });
  }
  
  Future<void> _activateEmergency() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // TODO: Implement actual emergency activation with the API
      // For now, we'll simulate a delay
      await Future.delayed(const Duration(seconds: 2));
      
      setState(() {
        _emergencyActivated = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.alertColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: _emergencyActivated 
          ? AppTheme.emergencyColor.withOpacity(0.05)
          : null,
      appBar: AppBar(
        title: Text(_emergencyActivated 
            ? l10n.emergencyModeActive
            : l10n.emergencyMode),
        backgroundColor: _emergencyActivated 
            ? AppTheme.emergencyColor
            : null,
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_emergencyActivated)
                _buildEmergencyActiveUI(context)
              else if (_isLoading && _countdownSeconds > 0)
                _buildCountdownUI(context)
              else
                _buildEmergencyReadyUI(context),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildEmergencyReadyUI(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.emergencyModeDescription,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 40),
          
          GestureDetector(
            onTap: _startEmergencyMode,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
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
                          l10n.tapToActivate,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppTheme.emergencyColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 40),
          
          Text(
            l10n.emergencyModeWarning,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.alertColor,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCountdownUI(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.activatingEmergencyIn(_countdownSeconds.toString()),
          style: Theme.of(context).textTheme.displayMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            color: AppTheme.emergencyColor.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              _countdownSeconds.toString(),
              style: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.bold,
                color: AppTheme.emergencyColor,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 32),
        
        ElevatedButton(
          onPressed: _cancelEmergency,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.emergencyColor,
            elevation: 0,
            side: const BorderSide(color: AppTheme.emergencyColor),
          ),
          child: Text(l10n.cancelEmergency),
        ),
        
        const SizedBox(height: 16),
        
        Text(
          l10n.tapToCancelEmergency,
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  Widget _buildEmergencyActiveUI(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.emergencyColor.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppTheme.secondaryColor,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.emergencyModeActivated,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: AppTheme.emergencyColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.monitoringDeviceNotified,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Emergency quick actions
          Text(
            l10n.emergencyActions,
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildEmergencyAction(
                context,
                Icons.camera_alt,
                l10n.takePhoto,
                () {
                  // TODO: Implement take photo
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.featureComingSoon)),
                  );
                },
              ),
              _buildEmergencyAction(
                context,
                Icons.mic,
                l10n.recordAudio,
                () {
                  // TODO: Implement record audio
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.featureComingSoon)),
                  );
                },
              ),
              _buildEmergencyAction(
                context,
                Icons.message,
                l10n.sendMessage,
                () {
                  // TODO: Implement send message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.featureComingSoon)),
                  );
                },
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          ElevatedButton(
            onPressed: _cancelEmergency,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.emergencyColor,
              elevation: 0,
              side: const BorderSide(color: AppTheme.emergencyColor),
            ),
            child: Text(l10n.deactivateEmergencyMode),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmergencyAction(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 90,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.emergencyColor.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.emergencyColor),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.emergencyColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}