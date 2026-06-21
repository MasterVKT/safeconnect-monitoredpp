import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FlashlightDisguise extends StatefulWidget {
  const FlashlightDisguise({super.key});

  @override
  State<FlashlightDisguise> createState() => _FlashlightDisguiseState();
}

class _FlashlightDisguiseState extends State<FlashlightDisguise> 
    with TickerProviderStateMixin {
  bool _isFlashlightOn = false;
  bool _isScreenLightOn = false;
  double _brightness = 1.0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  @override
  void initState() {
    super.initState();
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
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _turnOffFlashlight();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isScreenLightOn 
          ? Colors.white.withValues(alpha: _brightness)
          : Colors.black,
      appBar: AppBar(
        title: const Text('Flashlight'),
        backgroundColor: Colors.black87,
        iconTheme: IconThemeData(
          color: _isScreenLightOn ? Colors.black : Colors.white,
        ),
        titleTextStyle: TextStyle(
          color: _isScreenLightOn ? Colors.black : Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: _isScreenLightOn 
            ? Colors.white.withValues(alpha: _brightness)
            : Colors.black,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildFlashlightButton(),
            const SizedBox(height: 40),
            _buildScreenLightButton(),
            const SizedBox(height: 40),
            _buildBrightnessSlider(),
            const SizedBox(height: 40),
            _buildFlashlightStatus(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFlashlightButton() {
    return GestureDetector(
      onTap: _toggleFlashlight,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _isFlashlightOn ? _pulseAnimation.value : 1.0,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isFlashlightOn 
                    ? Colors.yellow.shade300
                    : Colors.grey.shade700,
                border: Border.all(
                  color: _isFlashlightOn 
                      ? Colors.yellow.shade600
                      : Colors.grey.shade500,
                  width: 4,
                ),
                boxShadow: _isFlashlightOn ? [
                  BoxShadow(
                    color: Colors.yellow.withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ] : null,
              ),
              child: Icon(
                Icons.flashlight_on,
                size: 80,
                color: _isFlashlightOn 
                    ? Colors.black87
                    : (_isScreenLightOn ? Colors.black54 : Colors.white70),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildScreenLightButton() {
    return ElevatedButton.icon(
      onPressed: _toggleScreenLight,
      icon: Icon(_isScreenLightOn ? Icons.lightbulb : Icons.lightbulb_outline),
      label: Text(_isScreenLightOn ? 'Screen Light ON' : 'Screen Light OFF'),
      style: ElevatedButton.styleFrom(
        backgroundColor: _isScreenLightOn 
            ? Colors.white 
            : Colors.grey.shade800,
        foregroundColor: _isScreenLightOn 
            ? Colors.black 
            : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );
  }
  
  Widget _buildBrightnessSlider() {
    if (!_isScreenLightOn) return const SizedBox.shrink();
    
    return Column(
      children: [
        Text(
          'Brightness',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          child: Slider(
            value: _brightness,
            min: 0.1,
            max: 1.0,
            divisions: 9,
            label: '${(_brightness * 100).round()}%',
            activeColor: Colors.grey.shade700,
            inactiveColor: Colors.grey.shade300,
            onChanged: (value) {
              setState(() {
                _brightness = value;
              });
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildFlashlightStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        color: (_isScreenLightOn ? Colors.black12 : Colors.grey.shade900)
            .withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LED Flash:',
                style: TextStyle(
                  color: _isScreenLightOn ? Colors.black87 : Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _isFlashlightOn ? 'ON' : 'OFF',
                style: TextStyle(
                  color: _isFlashlightOn 
                      ? (_isScreenLightOn ? Colors.green.shade700 : Colors.green.shade300)
                      : (_isScreenLightOn ? Colors.red.shade700 : Colors.red.shade300),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Screen Light:',
                style: TextStyle(
                  color: _isScreenLightOn ? Colors.black87 : Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _isScreenLightOn ? 'ON' : 'OFF',
                style: TextStyle(
                  color: _isScreenLightOn 
                      ? Colors.green.shade700
                      : (_isScreenLightOn ? Colors.red.shade700 : Colors.red.shade300),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  void _toggleFlashlight() {
    setState(() {
      _isFlashlightOn = !_isFlashlightOn;
    });
    
    if (_isFlashlightOn) {
      _turnOnFlashlight();
      _pulseController.repeat(reverse: true);
    } else {
      _turnOffFlashlight();
      _pulseController.stop();
    }
  }
  
  void _toggleScreenLight() {
    setState(() {
      _isScreenLightOn = !_isScreenLightOn;
    });
    
    if (_isScreenLightOn) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }
  
  void _turnOnFlashlight() {
    // In a real implementation, this would use camera flash
    // For this demo, we'll just show visual feedback
    HapticFeedback.lightImpact();
  }
  
  void _turnOffFlashlight() {
    // In a real implementation, this would turn off camera flash
    HapticFeedback.lightImpact();
  }
}