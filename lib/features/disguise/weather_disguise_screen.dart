import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'package:monitored_app/app/locator.dart';
import 'package:monitored_app/core/services/stealth_service.dart';

class WeatherDisguiseScreen extends StatefulWidget {
  const WeatherDisguiseScreen({Key? key}) : super(key: key);

  @override
  State<WeatherDisguiseScreen> createState() => _WeatherDisguiseScreenState();
}

class _WeatherDisguiseScreenState extends State<WeatherDisguiseScreen>
    with TickerProviderStateMixin {
  final StealthService _stealthService = locator<StealthService>();

  int _swipeCount = 0;
  DateTime? _lastSwipeTime;

  late AnimationController _cloudController;
  late AnimationController _sunController;
  late Animation<double> _cloudAnimation;
  late Animation<double> _sunAnimation;

  // Fake weather data
  final Map<String, dynamic> _currentWeather = {
    'temperature': 22,
    'condition': 'Partly Cloudy',
    'humidity': 65,
    'windSpeed': 12,
    'location': 'Current Location',
    'icon': Icons.wb_cloudy,
    'color': Colors.blue[300],
  };

  final List<Map<String, dynamic>> _forecast = [
    {
      'day': 'Today',
      'high': 25,
      'low': 18,
      'condition': 'Partly Cloudy',
      'icon': Icons.wb_cloudy,
    },
    {
      'day': 'Tomorrow',
      'high': 28,
      'low': 20,
      'condition': 'Sunny',
      'icon': Icons.wb_sunny,
    },
    {
      'day': 'Wednesday',
      'high': 24,
      'low': 16,
      'condition': 'Rainy',
      'icon': Icons.grain,
    },
    {
      'day': 'Thursday',
      'high': 26,
      'low': 19,
      'condition': 'Cloudy',
      'icon': Icons.cloud,
    },
    {
      'day': 'Friday',
      'high': 29,
      'low': 22,
      'condition': 'Sunny',
      'icon': Icons.wb_sunny,
    },
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadWeatherSettings();
  }

  void _setupAnimations() {
    _cloudController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    _sunController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );

    _cloudAnimation = Tween<double>(
      begin: -100,
      end: 100,
    ).animate(CurvedAnimation(
      parent: _cloudController,
      curve: Curves.linear,
    ));

    _sunAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _sunController,
      curve: Curves.linear,
    ));

    _cloudController.repeat();
    _sunController.repeat();
  }

  Future<void> _loadWeatherSettings() async {
    try {
      final uiConfig = await _stealthService.getCurrentUIConfig();
      if (uiConfig != null) {
        // Load custom weather settings
      }
    } catch (e) {
      debugPrint('Error loading weather settings: $e');
    }
  }

  void _handleRefresh() {
    // Simulate weather refresh
    HapticFeedback.lightImpact();

    // Add some randomness to temperature
    final random = math.Random();
    setState(() {
      _currentWeather['temperature'] = 20 + random.nextInt(15);
    });
  }

  void _onSwipe(DragEndDetails details) {
    if (details.primaryVelocity == null) return;

    // Check for four-finger swipe (secret gesture)
    final now = DateTime.now();

    // Reset swipe count if too much time has passed
    if (_lastSwipeTime == null ||
        now.difference(_lastSwipeTime!).inSeconds > 2) {
      _swipeCount = 1;
    } else {
      _swipeCount++;
    }

    _lastSwipeTime = now;

    // Secret gesture: four swipes in sequence
    if (_swipeCount >= 4) {
      _handleSecretAccess();
      _swipeCount = 0;
    }
  }

  void _handleSecretAccess() {
    HapticFeedback.heavyImpact();

    // Brief visual feedback - flash the weather icon
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (context) => const Center(
        child: Icon(
          Icons.flash_on,
          size: 100,
          color: Colors.yellow,
        ),
      ),
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      Navigator.of(context).pop(); // Close dialog
      Navigator.of(context).pushReplacementNamed('/main');
    });
  }

  @override
  void dispose() {
    _cloudController.dispose();
    _sunController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onPanEnd: _onSwipe,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.blue[400]!,
                Colors.blue[600]!,
                Colors.blue[800]!,
              ],
            ),
          ),
          child: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                _handleRefresh();
                await Future.delayed(const Duration(seconds: 1));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Weather',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.location_on,
                                color: Colors.white),
                            onPressed: () {
                              // Fake location action
                              HapticFeedback.lightImpact();
                            },
                          ),
                        ],
                      ),
                    ),

                    // Current Weather Card
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        margin: const EdgeInsets.all(20),
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _currentWeather['location'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Animated Weather Icon
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                // Animated sun
                                AnimatedBuilder(
                                  animation: _sunAnimation,
                                  child: Icon(
                                    Icons.wb_sunny,
                                    size: 80,
                                    color: Colors.yellow[300],
                                  ),
                                  builder: (context, child) {
                                    return Transform.rotate(
                                      angle: _sunAnimation.value,
                                      child: child,
                                    );
                                  },
                                ),

                                // Animated clouds
                                AnimatedBuilder(
                                  animation: _cloudAnimation,
                                  child: Icon(
                                    Icons.cloud,
                                    size: 60,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                  builder: (context, child) {
                                    return Transform.translate(
                                      offset: Offset(
                                          _cloudAnimation.value * 0.5, 0),
                                      child: child,
                                    );
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Temperature
                            Text(
                              '${_currentWeather['temperature']}°',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 72,
                                fontWeight: FontWeight.w100,
                              ),
                            ),

                            Text(
                              _currentWeather['condition'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w300,
                              ),
                            ),

                            const SizedBox(height: 30),

                            // Weather details
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildWeatherDetail(
                                  Icons.water_drop,
                                  '${_currentWeather['humidity']}%',
                                  'Humidity',
                                ),
                                _buildWeatherDetail(
                                  Icons.air,
                                  '${_currentWeather['windSpeed']} km/h',
                                  'Wind',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Forecast
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '5-Day Forecast',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 15),
                          ..._forecast.map((day) => _buildForecastItem(day)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Hint text (very subtle)
                    Opacity(
                      opacity: 0.3,
                      child: Text(
                        'Swipe down to refresh • Swipe patterns for more',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherDetail(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildForecastItem(Map<String, dynamic> day) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Day
          SizedBox(
            width: 80,
            child: Text(
              day['day'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),

          // Icon
          Icon(
            day['icon'],
            color: Colors.white70,
            size: 20,
          ),

          // Condition
          Expanded(
            child: Text(
              day['condition'],
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ),

          // Temperature range
          Text(
            '${day['high']}° / ${day['low']}°',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
