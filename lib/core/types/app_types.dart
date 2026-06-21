enum DataCategory {
  location,
  communication, // SMS, calls
  appUsage,
  media, // photos, audio, screenshots
  deviceInfo,
  contacts,
  calendar,
  fileAccess,
  camera,
  microphone,
  notifications;
}

enum ConsentLevel {
  // User has explicitly denied permission
  denied,
  // User has not been asked yet
  notRequested,
  // User was asked but didn't respond
  pending,
  // User gave basic consent
  implicit,
  // User gave explicit consent with full understanding
  explicit,
  // User gave ongoing consent for continuous monitoring
  ongoing,
  // User gave session-based consent (expires)
  session,
  // User gave consent with specific purpose limitation
  purposeLimited;
}

enum ProcessingPurpose {
  parentalControl,
  safetyMonitoring,
  emergencyResponse,
  locationTracking,
  screenTimeManagement,
  contentFiltering,
  behaviorAnalysis,
  deviceSecurity,
  dataBackup;
}

enum MetricType {
  latency,
  throughput,
  errorRate,
  memoryUsage,
  cpuUsage,
  batteryUsage,
  networkUsage,
  storageUsage,
  operationCount;
}

class ConsentRecord {
  final String id;
  final DataCategory category;
  final ProcessingPurpose purpose;
  final ConsentLevel level;
  final DateTime grantedAt;
  final DateTime? expiresAt;
  final DateTime? revokedAt;
  final String? restrictions;
  final Map<String, dynamic> metadata;

  ConsentRecord({
    required this.id,
    required this.category,
    required this.purpose,
    required this.level,
    required this.grantedAt,
    this.expiresAt,
    this.revokedAt,
    this.restrictions,
    this.metadata = const {},
  });

  bool get isActive {
    if (revokedAt != null) return false;
    if (expiresAt != null && DateTime.now().isAfter(expiresAt!)) return false;
    return level != ConsentLevel.denied;
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  factory ConsentRecord.fromJson(Map<String, dynamic> json) {
    return ConsentRecord(
      id: json['id'],
      category: DataCategory.values.firstWhere((c) => c.name == json['category']),
      purpose: ProcessingPurpose.values.firstWhere((p) => p.name == json['purpose']),
      level: ConsentLevel.values.firstWhere((l) => l.name == json['level']),
      grantedAt: DateTime.parse(json['granted_at']),
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
      revokedAt: json['revoked_at'] != null ? DateTime.parse(json['revoked_at']) : null,
      restrictions: json['restrictions'],
      metadata: json['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category.name,
      'purpose': purpose.name,
      'level': level.name,
      'granted_at': grantedAt.toUtc().toIso8601String(),
      'expires_at': expiresAt?.toUtc().toIso8601String(),
      'revoked_at': revokedAt?.toUtc().toIso8601String(),
      'restrictions': restrictions,
      'metadata': metadata,
    };
  }
}

class PerformanceMetric {
  final String id;
  final String operation;
  final MetricType type;
  final double value;
  final String unit;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  PerformanceMetric({
    required this.id,
    required this.operation,
    required this.type,
    required this.value,
    required this.unit,
    required this.timestamp,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'operation': operation,
      'type': type.name,
      'value': value,
      'unit': unit,
      'timestamp': timestamp.toUtc().toIso8601String(),
      'metadata': metadata,
    };
  }

  factory PerformanceMetric.fromJson(Map<String, dynamic> json) {
    return PerformanceMetric(
      id: json['id'],
      operation: json['operation'],
      type: MetricType.values.firstWhere((t) => t.name == json['type']),
      value: json['value'].toDouble(),
      unit: json['unit'],
      timestamp: DateTime.parse(json['timestamp']),
      metadata: json['metadata'] ?? {},
    );
  }
}