import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:monitored_app/core/services/database_service.dart';
import 'package:monitored_app/core/types/app_types.dart';
import 'package:monitored_app/app/locator.dart';

class ConsentRequest {
  final DataCategory category;
  final ProcessingPurpose purpose;
  final String title;
  final String description;
  final String? detailedExplanation;
  final bool isRequired;
  final Duration? sessionDuration;
  final List<String> dataTypes;
  final String? thirdPartySharing;

  ConsentRequest({
    required this.category,
    required this.purpose,
    required this.title,
    required this.description,
    this.detailedExplanation,
    this.isRequired = false,
    this.sessionDuration,
    this.dataTypes = const [],
    this.thirdPartySharing,
  });
}

class PrivacyReport {
  final DateTime periodStart;
  final DateTime periodEnd;
  final Map<DataCategory, int> dataProcessed;
  final Map<DataCategory, Duration> retentionSchedule;
  final List<String> sharingActivities;
  final List<ConsentRecord> consentChanges;

  PrivacyReport({
    required this.periodStart,
    required this.periodEnd,
    required this.dataProcessed,
    required this.retentionSchedule,
    required this.sharingActivities,
    required this.consentChanges,
  });

  Map<String, dynamic> toJson() {
    return {
      'period_start': periodStart.toIso8601String(),
      'period_end': periodEnd.toIso8601String(),
      'data_processed': dataProcessed.map((k, v) => MapEntry(k.name, v)),
      'retention_schedule': retentionSchedule.map((k, v) => MapEntry(k.name, v.inDays)),
      'sharing_activities': sharingActivities,
      'consent_changes': consentChanges.map((c) => c.toJson()).toList(),
    };
  }
}

class ConsentManager {
  static final ConsentManager _instance = ConsentManager._internal();
  factory ConsentManager() => _instance;
  ConsentManager._internal();

  final DatabaseService _databaseService = locator<DatabaseService>();

  final Map<DataCategory, ConsentRecord> _activeConsents = {};
  final List<ConsentRecord> _consentHistory = [];

  // Data retention policies (in days)
  final Map<DataCategory, Duration> _retentionPolicies = {
    DataCategory.location: const Duration(days: 90),
    DataCategory.communication: const Duration(days: 180),
    DataCategory.appUsage: const Duration(days: 365),
    DataCategory.media: const Duration(days: 30),
    DataCategory.deviceInfo: const Duration(days: 365),
    DataCategory.contacts: const Duration(days: 365),
    DataCategory.calendar: const Duration(days: 90),
    DataCategory.fileAccess: const Duration(days: 30),
    DataCategory.camera: const Duration(days: 30),
    DataCategory.microphone: const Duration(days: 30),
    DataCategory.notifications: const Duration(days: 7),
  };

  Future<void> initialize() async {
    await _loadConsentRecords();
    _scheduleConsentMaintenance();
    debugPrint('ConsentManager initialized with ${_activeConsents.length} active consents');
  }

  Future<void> _loadConsentRecords() async {
    try {
      final recordsData = await _databaseService.getConsentRecords();
      
      for (final recordData in recordsData) {
        final record = ConsentRecord.fromJson(recordData);
        _consentHistory.add(record);
        if (record.isActive) {
          _activeConsents[record.category] = record;
        }
      }
    } catch (e) {
      debugPrint('Error loading consent records: $e');
    }
  }

  /// Requests consent for a specific data category and purpose
  Future<ConsentLevel> requestConsent(ConsentRequest request) async {
    try {
      debugPrint('Requesting consent for ${request.category.name} - ${request.purpose.name}');
      
      // Check if we already have active consent
      final existingConsent = _activeConsents[request.category];
      if (existingConsent != null && _isConsentSufficient(existingConsent, request)) {
        return existingConsent.level;
      }
      
      // Show consent dialog to user
      final consentLevel = await _showConsentDialog(request);
      
      if (consentLevel != ConsentLevel.denied && consentLevel != ConsentLevel.notRequested) {
        await _recordConsent(request, consentLevel);
      }
      
      return consentLevel;
    } catch (e) {
      debugPrint('Error requesting consent: $e');
      return ConsentLevel.denied;
    }
  }

  bool _isConsentSufficient(ConsentRecord existing, ConsentRequest request) {
    // Check if existing consent covers the new purpose
    if (existing.purpose != request.purpose && !_isCompatiblePurpose(existing.purpose, request.purpose)) {
      return false;
    }
    
    // Check consent level requirements
    switch (request.category) {
      case DataCategory.location:
      case DataCategory.camera:
      case DataCategory.microphone:
        return existing.level.index >= ConsentLevel.explicit.index;
      case DataCategory.communication:
        return existing.level.index >= ConsentLevel.ongoing.index;
      default:
        return existing.level.index >= ConsentLevel.implicit.index;
    }
  }

  bool _isCompatiblePurpose(ProcessingPurpose existing, ProcessingPurpose requested) {
    // Define purpose compatibility matrix
    const compatiblePurposes = {
      ProcessingPurpose.parentalControl: [
        ProcessingPurpose.safetyMonitoring,
        ProcessingPurpose.screenTimeManagement,
        ProcessingPurpose.contentFiltering,
      ],
      ProcessingPurpose.safetyMonitoring: [
        ProcessingPurpose.emergencyResponse,
        ProcessingPurpose.locationTracking,
      ],
      ProcessingPurpose.emergencyResponse: [
        ProcessingPurpose.locationTracking,
        ProcessingPurpose.safetyMonitoring,
      ],
    };
    
    return compatiblePurposes[existing]?.contains(requested) ?? false;
  }

  Future<ConsentLevel> _showConsentDialog(ConsentRequest request) async {
    // This would show actual UI dialog in a real implementation
    // For now, returning a simulated response based on category sensitivity
    
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate user interaction
    
    // Simulate user decision based on category sensitivity
    switch (request.category) {
      case DataCategory.location:
      case DataCategory.camera:
      case DataCategory.microphone:
        return ConsentLevel.explicit;
      case DataCategory.communication:
        return ConsentLevel.ongoing;
      case DataCategory.appUsage:
      case DataCategory.deviceInfo:
        return ConsentLevel.implicit;
      default:
        return ConsentLevel.implicit;
    }
  }

  Future<void> _recordConsent(ConsentRequest request, ConsentLevel level) async {
    final consentId = _generateConsentId();
    final now = DateTime.now();
    
    DateTime? expiresAt;
    if (request.sessionDuration != null) {
      expiresAt = now.add(request.sessionDuration!);
    } else if (level == ConsentLevel.session) {
      expiresAt = now.add(const Duration(hours: 24));
    }
    
    final consent = ConsentRecord(
      id: consentId,
      category: request.category,
      purpose: request.purpose,
      level: level,
      grantedAt: now,
      expiresAt: expiresAt,
      metadata: {
        'request_title': request.title,
        'request_description': request.description,
        'data_types': request.dataTypes,
        'third_party_sharing': request.thirdPartySharing,
        'user_agent': 'monitored_app_v1.0',
      },
    );
    
    // Store in database
    await _databaseService.insertConsentRecord(consent);
    
    // Update active consents
    _activeConsents[request.category] = consent;
    _consentHistory.add(consent);
    
    debugPrint('Consent recorded: ${request.category.name} -> ${level.name}');
  }

  /// Revokes consent for a specific category
  Future<void> revokeConsent(DataCategory category, {String? reason}) async {
    final existingConsent = _activeConsents[category];
    if (existingConsent == null) return;
    
    final revokedConsent = ConsentRecord(
      id: existingConsent.id,
      category: existingConsent.category,
      purpose: existingConsent.purpose,
      level: existingConsent.level,
      grantedAt: existingConsent.grantedAt,
      expiresAt: existingConsent.expiresAt,
      revokedAt: DateTime.now(),
      restrictions: existingConsent.restrictions,
      metadata: {
        ...existingConsent.metadata,
        'revocation_reason': reason,
      },
    );
    
    await _databaseService.updateConsentRecord(revokedConsent);
    
    _activeConsents.remove(category);
    _consentHistory.add(revokedConsent);
    
    // Trigger data cleanup for revoked consent
    await _cleanupRevokedData(category);
    
    debugPrint('Consent revoked for ${category.name}');
  }

  /// Checks if we have valid consent for a specific operation
  bool hasValidConsent(DataCategory category, ProcessingPurpose purpose) {
    final consent = _activeConsents[category];
    if (consent == null || !consent.isActive) return false;
    
    return consent.purpose == purpose || _isCompatiblePurpose(consent.purpose, purpose);
  }

  /// Gets the current consent level for a category
  ConsentLevel? getConsentLevel(DataCategory category) {
    final consent = _activeConsents[category];
    return consent?.isActive == true ? consent?.level : null;
  }

  /// Generates a privacy report for GDPR compliance
  Future<PrivacyReport> generatePrivacyReport(DateTime start, DateTime end) async {
    final dataProcessed = await _getDataProcessingStats(start, end);
    final sharingActivities = await _getDataSharingActivities(start, end);
    final consentChanges = _getConsentChangesInPeriod(start, end);
    
    return PrivacyReport(
      periodStart: start,
      periodEnd: end,
      dataProcessed: dataProcessed,
      retentionSchedule: _retentionPolicies,
      sharingActivities: sharingActivities,
      consentChanges: consentChanges,
    );
  }

  Future<Map<DataCategory, int>> _getDataProcessingStats(DateTime start, DateTime end) async {
    // Query database for data processing statistics
    // This would return actual counts from the database
    return {
      for (final category in DataCategory.values)
        category: 0, // Placeholder - implement actual counting
    };
  }

  Future<List<String>> _getDataSharingActivities(DateTime start, DateTime end) async {
    // Query for data sharing/export activities
    return [
      'Data sync to parent dashboard',
      'Emergency alerts to emergency contacts',
      'Anonymized usage statistics to analytics service',
    ];
  }

  List<ConsentRecord> _getConsentChangesInPeriod(DateTime start, DateTime end) {
    return _consentHistory.where((record) {
      final changeTime = record.revokedAt ?? record.grantedAt;
      return changeTime.isAfter(start) && changeTime.isBefore(end);
    }).toList();
  }

  /// Schedules periodic consent maintenance tasks
  void _scheduleConsentMaintenance() {
    Timer.periodic(const Duration(hours: 6), (_) => _performConsentMaintenance());
  }

  Future<void> _performConsentMaintenance() async {
    try {
      // Check for expired consents
      final expiredConsents = _activeConsents.values.where((c) => c.isExpired).toList();
      
      for (final expired in expiredConsents) {
        debugPrint('Consent expired for ${expired.category.name}');
        _activeConsents.remove(expired.category);
        
        // Optionally request renewal
        if (expired.level.index >= ConsentLevel.explicit.index) {
          await _requestConsentRenewal(expired);
        }
      }
      
      // Cleanup old data based on retention policies
      await _performDataRetentionCleanup();
      
    } catch (e) {
      debugPrint('Error in consent maintenance: $e');
    }
  }

  Future<void> _requestConsentRenewal(ConsentRecord expired) async {
    // Create renewal request
    final renewalRequest = ConsentRequest(
      category: expired.category,
      purpose: expired.purpose,
      title: 'Renew ${expired.category.name} access',
      description: 'Your consent for ${expired.category.name} monitoring has expired. Please renew to continue.',
      isRequired: false,
    );
    
    // Request renewal (this would show UI in real implementation)
    await requestConsent(renewalRequest);
  }

  Future<void> _performDataRetentionCleanup() async {
    for (final entry in _retentionPolicies.entries) {
      final category = entry.key;
      final retention = entry.value;
      final cutoffDate = DateTime.now().subtract(retention);
      
      await _databaseService.deleteOldDataByCategory(category, cutoffDate);
    }
  }

  Future<void> _cleanupRevokedData(DataCategory category) async {
    // Immediately remove data for revoked consent
    await _databaseService.deleteAllDataByCategory(category);
    debugPrint('Cleaned up data for revoked consent: ${category.name}');
  }

  String _generateConsentId() {
    return 'consent_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().hashCode}';
  }

  /// Gets all active consents
  Map<DataCategory, ConsentRecord> getActiveConsents() {
    return Map.unmodifiable(_activeConsents);
  }

  /// Gets consent history
  List<ConsentRecord> getConsentHistory() {
    return List.unmodifiable(_consentHistory);
  }

  /// Updates retention policy for a data category
  void updateRetentionPolicy(DataCategory category, Duration retention) {
    _retentionPolicies[category] = retention;
    debugPrint('Updated retention policy for ${category.name}: ${retention.inDays} days');
  }
}