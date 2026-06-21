import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monitored_app/app/routes.dart';
import 'package:monitored_app/app/locator.dart';
import 'package:monitored_app/core/privacy/consent_manager.dart';
import 'package:monitored_app/core/services/storage_service.dart';
import 'package:monitored_app/core/types/app_types.dart';
import 'package:monitored_app/features/auth/widgets/digital_consent.dart';
import 'package:monitored_app/generated/l10n/app_localizations.dart';

class ConsentScreen extends ConsumerStatefulWidget {
  const ConsentScreen({super.key});

  @override
  ConsumerState<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends ConsumerState<ConsentScreen> {
  bool _isLoading = false;
  late final ConsentManager _consentManager;
  late final StorageService _storageService;

  @override
  void initState() {
    super.initState();
    _consentManager = ConsentManager();
    _storageService = locator<StorageService>();
  }

  Future<void> _handleConsentGiven(
    Uint8List signature, 
    Map<String, dynamic> consentData,
  ) async {
    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('Processing consent data and signature...');
      
      // Store digital signature securely
      final signatureBase64 = base64Encode(signature);
      await _storageService.write('user_consent_signature', signatureBase64);
      await _storageService.write('consent_timestamp', DateTime.now().toIso8601String());
      
      // Store consent data
      await _storageService.write('user_consent_data', jsonEncode(consentData));
      
      // Request consent for all monitoring categories using ConsentManager
      final consentRequests = [
        ConsentRequest(
          category: DataCategory.location,
          purpose: ProcessingPurpose.parentalControl,
          title: 'Location Monitoring',
          description: 'Track device location for safety purposes',
          isRequired: true,
          dataTypes: ['GPS coordinates', 'Network location', 'Location history'],
        ),
        ConsentRequest(
          category: DataCategory.communication,
          purpose: ProcessingPurpose.parentalControl,
          title: 'Communication Monitoring',
          description: 'Monitor SMS, calls, and messaging apps',
          isRequired: true,
          dataTypes: ['SMS messages', 'Call logs', 'App messages'],
        ),
        ConsentRequest(
          category: DataCategory.appUsage,
          purpose: ProcessingPurpose.screenTimeManagement,
          title: 'App Usage Monitoring',
          description: 'Track application usage and screen time',
          isRequired: true,
          dataTypes: ['App usage statistics', 'Screen time data', 'App installation data'],
        ),
        ConsentRequest(
          category: DataCategory.media,
          purpose: ProcessingPurpose.safetyMonitoring,
          title: 'Media Access',
          description: 'Access camera and microphone for emergency situations',
          isRequired: true,
          dataTypes: ['Emergency photos', 'Emergency audio recordings'],
        ),
        ConsentRequest(
          category: DataCategory.deviceInfo,
          purpose: ProcessingPurpose.parentalControl,
          title: 'Device Information',
          description: 'Collect device information and status',
          isRequired: true,
          dataTypes: ['Device model', 'OS version', 'Battery status', 'Network status'],
        ),
        ConsentRequest(
          category: DataCategory.contacts,
          purpose: ProcessingPurpose.parentalControl,
          title: 'Contact Access',
          description: 'Access contacts for emergency features',
          isRequired: false,
          dataTypes: ['Contact list', 'Emergency contacts'],
        ),
      ];
      
      // Record all consents
      for (final request in consentRequests) {
        final consentLevel = await _consentManager.requestConsent(request);
        debugPrint('Consent for ${request.category.name}: ${consentLevel.name}');
      }
      
      // Mark consent as completed
      await _storageService.write('consent_completed', 'true');
      
      debugPrint('Consent processing completed successfully');
      
      // Navigate to permission screen
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.permissions);
      }
    } catch (e) {
      debugPrint('Error processing consent: $e');
      
      // Handle error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing consent: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleConsentCancelled() {
    // Go back to pairing screen
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                l10n.processingConsent,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.pleaseWait,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    return DigitalConsentWidget(
      onConsentGiven: _handleConsentGiven,
      onCancel: _handleConsentCancelled,
    );
  }
}