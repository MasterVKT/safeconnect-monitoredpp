import 'package:flutter/material.dart';
import 'package:monitored_app/core/services/stealth_service.dart';
import 'package:monitored_app/features/disguise/views/calculator_disguise.dart';
import 'package:monitored_app/features/disguise/views/flashlight_disguise.dart';
import 'package:monitored_app/features/home/main_screen.dart';

class DisguiseManager {
  static Widget getDisguiseWidget(DisguiseType disguiseType) {
    switch (disguiseType) {
      case DisguiseType.calculator:
        return const CalculatorDisguise();
      case DisguiseType.flashlight:
        return const FlashlightDisguise();
      case DisguiseType.weather:
        return const WeatherDisguise();
      case DisguiseType.notes:
        return const NotesDisguise();
      case DisguiseType.calendar:
        return const CalendarDisguise();
      case DisguiseType.gameApp:
        return const GameDisguise();
      case DisguiseType.utilityApp:
        return const UtilityDisguise();
      case DisguiseType.custom:
        return const CustomDisguise();
      case DisguiseType.none:
        return const MainScreen();
    }
  }

  static String getDisguiseTitle(DisguiseType disguiseType) {
    switch (disguiseType) {
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
        return 'Puzzle Game';
      case DisguiseType.utilityApp:
        return 'Quick Tools';
      case DisguiseType.custom:
        return 'Custom App';
      case DisguiseType.none:
        return 'XP SafeConnect';
    }
  }

  static IconData getDisguiseIcon(DisguiseType disguiseType) {
    switch (disguiseType) {
      case DisguiseType.calculator:
        return Icons.calculate;
      case DisguiseType.flashlight:
        return Icons.flashlight_on;
      case DisguiseType.weather:
        return Icons.wb_sunny;
      case DisguiseType.notes:
        return Icons.note;
      case DisguiseType.calendar:
        return Icons.calendar_today;
      case DisguiseType.gameApp:
        return Icons.games;
      case DisguiseType.utilityApp:
        return Icons.build;
      case DisguiseType.custom:
        return Icons.apps;
      case DisguiseType.none:
        return Icons.security;
    }
  }
}

// Placeholder widgets for other disguise types
class WeatherDisguise extends StatelessWidget {
  const WeatherDisguise({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather'),
        backgroundColor: Colors.blue,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wb_sunny, size: 100, color: Colors.orange),
            SizedBox(height: 20),
            Text('22°C', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
            Text('Sunny', style: TextStyle(fontSize: 24)),
            SizedBox(height: 20),
            Text('Coming soon...', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class NotesDisguise extends StatelessWidget {
  const NotesDisguise({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        backgroundColor: Colors.amber,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.note, size: 100, color: Colors.amber),
            SizedBox(height: 20),
            Text('Notes App', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Text('Coming soon...', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class CalendarDisguise extends StatelessWidget {
  const CalendarDisguise({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        backgroundColor: Colors.red,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 100, color: Colors.red),
            SizedBox(height: 20),
            Text('Calendar App', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Text('Coming soon...', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class GameDisguise extends StatelessWidget {
  const GameDisguise({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Puzzle Game'),
        backgroundColor: Colors.purple,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.games, size: 100, color: Colors.purple),
            SizedBox(height: 20),
            Text('Puzzle Game', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Text('Coming soon...', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class UtilityDisguise extends StatelessWidget {
  const UtilityDisguise({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Tools'),
        backgroundColor: Colors.teal,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.build, size: 100, color: Colors.teal),
            SizedBox(height: 20),
            Text('Quick Tools', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Text('Coming soon...', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class CustomDisguise extends StatelessWidget {
  const CustomDisguise({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom App'),
        backgroundColor: Colors.grey,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.apps, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text('Custom App', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Text('Custom disguise configuration...', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}