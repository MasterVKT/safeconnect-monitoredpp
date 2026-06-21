import 'dart:math';
import 'package:flutter/foundation.dart';

enum RiskLevel {
  none(0),
  low(1),
  medium(2),
  high(3),
  critical(4);

  const RiskLevel(this.value);
  final int value;
}

enum BehaviorCategory {
  appUsage,
  communication,
  location,
  timePatterns,
  deviceInteraction;
}

class BehaviorPattern {
  final String id;
  final BehaviorCategory category;
  final String description;
  final RiskLevel riskLevel;
  final Map<String, dynamic> metadata;
  final DateTime detectedAt;
  final double confidence;

  BehaviorPattern({
    required this.id,
    required this.category,
    required this.description,
    required this.riskLevel,
    required this.metadata,
    required this.detectedAt,
    required this.confidence,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category.name,
      'description': description,
      'risk_level': riskLevel.name,
      'metadata': metadata,
      'detected_at': detectedAt.toIso8601String(),
      'confidence': confidence,
    };
  }
}

class UsageStats {
  final String appPackage;
  final String appName;
  final Duration totalTime;
  final int launchCount;
  final DateTime firstUsed;
  final DateTime lastUsed;
  final List<DateTime> usageSessions;

  UsageStats({
    required this.appPackage,
    required this.appName,
    required this.totalTime,
    required this.launchCount,
    required this.firstUsed,
    required this.lastUsed,
    required this.usageSessions,
  });
}

class BehaviorAnalyzer {
  static final BehaviorAnalyzer _instance = BehaviorAnalyzer._internal();
  factory BehaviorAnalyzer() => _instance;
  BehaviorAnalyzer._internal();

  // Analysis configuration
  static const Duration _analysisWindow = Duration(days: 7);

  /// Performs comprehensive behavioral analysis
  Future<List<BehaviorPattern>> analyzeAllBehaviors() async {
    final patterns = <BehaviorPattern>[];
    
    try {
      // Analyze different behavioral aspects
      patterns.addAll(await _analyzeAppUsagePatterns());
      patterns.addAll(await _analyzeCommunicationPatterns());
      patterns.addAll(await _analyzeLocationPatterns());
      patterns.addAll(await _analyzeTimePatterns());
      patterns.addAll(await _analyzeDeviceInteractionPatterns());
      
      // Sort by risk level and confidence
      patterns.sort((a, b) {
        final riskCompare = b.riskLevel.value.compareTo(a.riskLevel.value);
        if (riskCompare != 0) return riskCompare;
        return b.confidence.compareTo(a.confidence);
      });
      
      debugPrint('Behavioral analysis complete: ${patterns.length} patterns detected');
      return patterns;
    } catch (e) {
      debugPrint('Error in behavioral analysis: $e');
      return [];
    }
  }

  /// Analyzes app usage patterns for addiction, productivity, and anomalies
  Future<List<BehaviorPattern>> _analyzeAppUsagePatterns() async {
    final patterns = <BehaviorPattern>[];
    
    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(_analysisWindow);
      
      // Get app usage data from database
      final appUsageData = await _getAppUsageData(weekAgo, now);
      final usageStats = _calculateUsageStats(appUsageData);
      
      // Analyze for addiction patterns
      patterns.addAll(_detectAddictionPatterns(usageStats));
      
      // Analyze productivity patterns
      patterns.addAll(_analyzeProductivityPatterns(usageStats));
      
      // Detect usage anomalies
      patterns.addAll(_detectUsageAnomalies(usageStats));
      
      return patterns;
    } catch (e) {
      debugPrint('Error analyzing app usage patterns: $e');
      return [];
    }
  }

  List<BehaviorPattern> _detectAddictionPatterns(List<UsageStats> usageStats) {
    final patterns = <BehaviorPattern>[];
    
    for (final stats in usageStats) {
      final dailyAverageMinutes = stats.totalTime.inMinutes / 7;
      
      // High usage threshold: more than 4 hours per day
      if (dailyAverageMinutes > 240) {
        patterns.add(BehaviorPattern(
          id: 'addiction_${stats.appPackage}_${DateTime.now().millisecondsSinceEpoch}',
          category: BehaviorCategory.appUsage,
          description: 'Potential addiction to ${stats.appName}: ${dailyAverageMinutes.round()} min/day average',
          riskLevel: dailyAverageMinutes > 480 ? RiskLevel.high : RiskLevel.medium,
          metadata: {
            'app_package': stats.appPackage,
            'app_name': stats.appName,
            'daily_average_minutes': dailyAverageMinutes,
            'total_launches': stats.launchCount,
            'pattern_type': 'excessive_usage',
          },
          detectedAt: DateTime.now(),
          confidence: min(1.0, dailyAverageMinutes / 480),
        ));
      }
      
      // Frequent launching pattern
      if (stats.launchCount > 100) {
        patterns.add(BehaviorPattern(
          id: 'frequent_launch_${stats.appPackage}_${DateTime.now().millisecondsSinceEpoch}',
          category: BehaviorCategory.appUsage,
          description: 'Frequent app switching to ${stats.appName}: ${stats.launchCount} launches in 7 days',
          riskLevel: RiskLevel.low,
          metadata: {
            'app_package': stats.appPackage,
            'app_name': stats.appName,
            'launch_count': stats.launchCount,
            'pattern_type': 'frequent_switching',
          },
          detectedAt: DateTime.now(),
          confidence: min(1.0, stats.launchCount / 200),
        ));
      }
    }
    
    return patterns;
  }

  List<BehaviorPattern> _analyzeProductivityPatterns(List<UsageStats> usageStats) {
    final patterns = <BehaviorPattern>[];
    
    // Categorize apps by type
    final entertainmentApps = usageStats.where((s) => _isEntertainmentApp(s.appPackage)).toList();
    final productiveApps = usageStats.where((s) => _isProductiveApp(s.appPackage)).toList();
    
    final totalEntertainmentTime = entertainmentApps.fold(Duration.zero, (sum, s) => sum + s.totalTime);
    final totalProductiveTime = productiveApps.fold(Duration.zero, (sum, s) => sum + s.totalTime);
    
    if (totalEntertainmentTime.inMinutes > 0 && totalProductiveTime.inMinutes > 0) {
      final entertainmentRatio = totalEntertainmentTime.inMinutes / (totalEntertainmentTime.inMinutes + totalProductiveTime.inMinutes);
      
      if (entertainmentRatio > 0.8) {
        patterns.add(BehaviorPattern(
          id: 'low_productivity_${DateTime.now().millisecondsSinceEpoch}',
          category: BehaviorCategory.appUsage,
          description: 'Low productivity pattern: ${(entertainmentRatio * 100).round()}% entertainment usage',
          riskLevel: RiskLevel.medium,
          metadata: {
            'entertainment_ratio': entertainmentRatio,
            'entertainment_minutes': totalEntertainmentTime.inMinutes,
            'productive_minutes': totalProductiveTime.inMinutes,
            'pattern_type': 'productivity_analysis',
          },
          detectedAt: DateTime.now(),
          confidence: entertainmentRatio,
        ));
      }
    }
    
    return patterns;
  }

  List<BehaviorPattern> _detectUsageAnomalies(List<UsageStats> usageStats) {
    final patterns = <BehaviorPattern>[];
    
    for (final stats in usageStats) {
      // Analyze usage time distribution
      final hourlyUsage = _calculateHourlyUsage(stats.usageSessions);
      final nightUsage = _calculateNightUsage(hourlyUsage);
      
      // Detect unusual late-night usage
      if (nightUsage.inMinutes > 60) {
        patterns.add(BehaviorPattern(
          id: 'night_usage_${stats.appPackage}_${DateTime.now().millisecondsSinceEpoch}',
          category: BehaviorCategory.timePatterns,
          description: 'Unusual late-night usage of ${stats.appName}: ${nightUsage.inMinutes} min between 11PM-6AM',
          riskLevel: RiskLevel.low,
          metadata: {
            'app_package': stats.appPackage,
            'app_name': stats.appName,
            'night_usage_minutes': nightUsage.inMinutes,
            'pattern_type': 'temporal_anomaly',
          },
          detectedAt: DateTime.now(),
          confidence: min(1.0, nightUsage.inMinutes / 180),
        ));
      }
    }
    
    return patterns;
  }

  /// Analyzes communication patterns for potential risks
  Future<List<BehaviorPattern>> _analyzeCommunicationPatterns() async {
    final patterns = <BehaviorPattern>[];
    
    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(_analysisWindow);
      
      // Analyze SMS patterns
      final smsPatterns = await _analyzeSmsPatterns(weekAgo, now);
      patterns.addAll(smsPatterns);
      
      // Analyze call patterns
      final callPatterns = await _analyzeCallPatterns(weekAgo, now);
      patterns.addAll(callPatterns);
      
      return patterns;
    } catch (e) {
      debugPrint('Error analyzing communication patterns: $e');
      return [];
    }
  }

  Future<List<BehaviorPattern>> _analyzeSmsPatterns(DateTime start, DateTime end) async {
    final patterns = <BehaviorPattern>[];
    
    // This would query the database for SMS data
    // For now, returning empty list
    // In real implementation:
    // - Detect unusual contact patterns
    // - Identify potential cyberbullying language
    // - Flag communications with unknown numbers
    // - Analyze frequency and timing patterns
    
    return patterns;
  }

  Future<List<BehaviorPattern>> _analyzeCallPatterns(DateTime start, DateTime end) async {
    final patterns = <BehaviorPattern>[];
    
    // Similar to SMS analysis but for calls
    // - Unusual call durations
    // - Calls at unusual times
    // - Frequent calls to unknown numbers
    
    return patterns;
  }

  /// Analyzes location patterns for safety and behavioral insights
  Future<List<BehaviorPattern>> _analyzeLocationPatterns() async {
    final patterns = <BehaviorPattern>[];
    
    try {
      // Get location data from database
      // Analyze for:
      // - Unusual locations
      // - Time spent in different areas
      // - Movement patterns
      // - Safety zones vs risk areas

      return patterns;
    } catch (e) {
      debugPrint('Error analyzing location patterns: $e');
      return [];
    }
  }

  /// Analyzes temporal usage patterns
  Future<List<BehaviorPattern>> _analyzeTimePatterns() async {
    final patterns = <BehaviorPattern>[];
    
    try {
      // Analyze overall device usage patterns by time of day
      // - Sleep schedule consistency
      // - Peak usage times
      // - Weekend vs weekday patterns
      
      return patterns;
    } catch (e) {
      debugPrint('Error analyzing time patterns: $e');
      return [];
    }
  }

  /// Analyzes device interaction patterns
  Future<List<BehaviorPattern>> _analyzeDeviceInteractionPatterns() async {
    final patterns = <BehaviorPattern>[];
    
    try {
      // Analyze:
      // - Screen unlock frequency
      // - Notification response times
      // - App switching patterns
      // - Input method usage
      
      return patterns;
    } catch (e) {
      debugPrint('Error analyzing device interaction patterns: $e');
      return [];
    }
  }

  // Helper methods
  Future<List<Map<String, dynamic>>> _getAppUsageData(DateTime start, DateTime end) async {
    // Query database for app usage data in the time range
    // This is a placeholder - implement actual database query
    return [];
  }

  List<UsageStats> _calculateUsageStats(List<Map<String, dynamic>> rawData) {
    // Process raw data into UsageStats objects
    // This is a placeholder - implement actual calculation
    return [];
  }

  bool _isEntertainmentApp(String packageName) {
    final entertainmentPatterns = [
      'com.instagram.android',
      'com.snapchat.android',
      'com.zhiliaoapp.musically', // TikTok
      'com.netflix.mediaclient',
      'com.spotify.music',
      'com.google.android.youtube',
    ];
    
    return entertainmentPatterns.any((pattern) => packageName.contains(pattern.split('.').last));
  }

  bool _isProductiveApp(String packageName) {
    final productivePatterns = [
      'com.microsoft.office',
      'com.google.android.apps.docs',
      'com.adobe.reader',
      'org.mozilla.firefox',
      'com.android.chrome',
    ];
    
    return productivePatterns.any((pattern) => packageName.contains(pattern.split('.').last));
  }

  Map<int, Duration> _calculateHourlyUsage(List<DateTime> sessions) {
    final hourlyUsage = <int, Duration>{};
    
    for (final session in sessions) {
      final hour = session.hour;
      hourlyUsage[hour] = (hourlyUsage[hour] ?? Duration.zero) + const Duration(minutes: 1);
    }
    
    return hourlyUsage;
  }

  Duration _calculateNightUsage(Map<int, Duration> hourlyUsage) {
    Duration nightUsage = Duration.zero;
    
    // Night hours: 23:00 - 06:00
    for (int hour = 23; hour <= 23; hour++) {
      nightUsage += hourlyUsage[hour] ?? Duration.zero;
    }
    for (int hour = 0; hour <= 6; hour++) {
      nightUsage += hourlyUsage[hour] ?? Duration.zero;
    }
    
    return nightUsage;
  }

  /// Generates a behavioral report for a given time period
  Future<Map<String, dynamic>> generateBehaviorReport(DateTime start, DateTime end) async {
    final patterns = await analyzeAllBehaviors();
    
    return {
      'analysis_period': {
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
      },
      'summary': {
        'total_patterns': patterns.length,
        'high_risk_patterns': patterns.where((p) => p.riskLevel.value >= 3).length,
        'medium_risk_patterns': patterns.where((p) => p.riskLevel.value == 2).length,
        'low_risk_patterns': patterns.where((p) => p.riskLevel.value == 1).length,
      },
      'patterns': patterns.map((p) => p.toJson()).toList(),
      'recommendations': _generateRecommendations(patterns),
    };
  }

  List<String> _generateRecommendations(List<BehaviorPattern> patterns) {
    final recommendations = <String>[];
    
    // Generate contextual recommendations based on detected patterns
    final highRiskPatterns = patterns.where((p) => p.riskLevel.value >= 3).toList();
    
    if (highRiskPatterns.isNotEmpty) {
      recommendations.add('Consider implementing app time limits for high-usage applications');
    }
    
    final addictionPatterns = patterns.where((p) => p.metadata['pattern_type'] == 'excessive_usage').toList();
    if (addictionPatterns.isNotEmpty) {
      recommendations.add('Schedule regular breaks from high-usage applications');
    }
    
    return recommendations;
  }
}