import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:monitored_app/app/locator.dart';
import 'package:monitored_app/core/services/stealth_service.dart';

class FlashlightDisguiseScreen extends StatefulWidget {
  const FlashlightDisguiseScreen({Key? key}) : super(key: key);

  @override
  State<FlashlightDisguiseScreen> createState() => _FlashlightDisguiseScreenState();
}

class _FlashlightDisguiseScreenState extends State<FlashlightDisguiseScreen>
    with TickerProviderStateMixin {
  final StealthService _stealthService = locator<StealthService>();
  
  bool _isFlashlightOn = false;
  double _brightness = 0.8;
  int _tapCount = 0;
  DateTime? _lastTapTime;
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _brightnessController;
  late Animation<double> _brightnessAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadFlashlightSettings();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _brightnessController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _brightnessAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _brightnessController,
      curve: Curves.easeOut,
    ));
  }

  Future<void> _loadFlashlightSettings() async {
    try {
      final uiConfig = await _stealthService.getCurrentUIConfig();
      if (uiConfig != null) {
        // Load custom settings for flashlight disguise
        setState(() {
          _brightness = (uiConfig['default_brightness'] ?? 0.8).toDouble();
        });
      }
    } catch (e) {
      debugPrint('Error loading flashlight settings: $e');
    }
  }

  void _toggleFlashlight() {
    setState(() {
      _isFlashlightOn = !_isFlashlightOn;
    });

    if (_isFlashlightOn) {
      _brightnessController.forward();
      _pulseController.repeat(reverse: true);
    } else {
      _brightnessController.reverse();
      _pulseController.stop();
    }

    _checkSecretGesture();
    HapticFeedback.mediumImpact();
  }

  void _checkSecretGesture() {
    final now = DateTime.now();
    
    // Reset tap count if too much time has passed
    if (_lastTapTime == null || 
        now.difference(_lastTapTime!).inMilliseconds > 1000) {
      _tapCount = 1;
    } else {
      _tapCount++;
    }
    
    _lastTapTime = now;
    
    // Secret gesture: triple tap
    if (_tapCount >= 3) {
      _handleSecretAccess();
      _tapCount = 0;
    }
  }

  void _handleSecretAccess() {
    // Brief visual feedback
    HapticFeedback.heavyImpact();
    
    // Flash effect
    setState(() {
      _isFlashlightOn = true;
    });
    
    _brightnessController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 200), () {
        _brightnessController.reverse().then((_) {
          Navigator.of(context).pushReplacementNamed('/main');
        });
      });
    });
  }

  void _onBrightnessChanged(double value) {
    setState(() {
      _brightness = value;
    });
    
    if (_isFlashlightOn) {
      HapticFeedback.selectionClick();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _brightnessController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Flashlight'),
        backgroundColor: Colors.grey[900],
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              Colors.grey[900]!,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Flashlight Visual Effect
            AnimatedBuilder(
              animation: _brightnessAnimation,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.yellow[100],
                    boxShadow: [
                      BoxShadow(
                        color: Colors.yellow.withValues(alpha: 0.5),
                        blurRadius: 50,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.lightbulb,
                    size: 80,
                    color: Colors.orange,
                  ),
                ),
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isFlashlightOn ? _pulseAnimation.value : 0.8,
                    child: child,
                  );
                },
              ),
              builder: (context, child) {
                return Opacity(
                  opacity: _brightnessAnimation.value * _brightness,
                  child: child,
                );
              },
            ),
            
            const SizedBox(height: 60),
            
            // Toggle Button
            GestureDetector(
              onTap: _toggleFlashlight,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isFlashlightOn ? Colors.yellow[600] : Colors.grey[700],
                  border: Border.all(
                    color: Colors.white30,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _isFlashlightOn 
                          ? Colors.yellow.withValues(alpha: 0.3)
                          : Colors.black26,
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(
                  _isFlashlightOn ? Icons.flash_on : Icons.flash_off,
                  size: 50,
                  color: _isFlashlightOn ? Colors.black87 : Colors.white70,
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Status Text
            Text(
              _isFlashlightOn ? 'ON' : 'OFF',
              style: TextStyle(
                color: _isFlashlightOn ? Colors.yellow[300] : Colors.grey[500],
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            
            const SizedBox(height: 60),
            
            // Brightness Slider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  Text(
                    'Brightness',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.yellow[600],
                      inactiveTrackColor: Colors.grey[700],
                      thumbColor: Colors.yellow[500],
                      overlayColor: Colors.yellow.withValues(alpha: 0.2),
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 12,
                      ),
                    ),
                    child: Slider(
                      value: _brightness,
                      min: 0.1,
                      max: 1.0,
                      divisions: 9,
                      onChanged: _onBrightnessChanged,
                    ),
                  ),
                  Text(
                    '${(_brightness * 100).round()}%',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Hint Text (subtle)
            Opacity(
              opacity: 0.3,
              child: Text(
                'Triple tap for settings',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}