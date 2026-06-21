import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'package:monitored_app/generated/l10n/app_localizations.dart';

class DigitalConsentWidget extends StatefulWidget {
  final Function(Uint8List signature, Map<String, dynamic> consentData) onConsentGiven;
  final VoidCallback? onCancel;

  const DigitalConsentWidget({
    super.key,
    required this.onConsentGiven,
    this.onCancel,
  });

  @override
  State<DigitalConsentWidget> createState() => _DigitalConsentWidgetState();
}

class _DigitalConsentWidgetState extends State<DigitalConsentWidget> {
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 2,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  final ScrollController _scrollController = ScrollController();
  bool _hasReadTerms = false;
  bool _hasReadPrivacy = false;
  bool _agreeToMonitoring = false;
  bool _understandDataCollection = false;
  bool _isAdult = false;
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _consentItems = [
    'Location tracking and GPS monitoring',
    'SMS and messaging app monitoring',
    'Call log access and monitoring',
    'Application usage tracking',
    'Remote camera and audio access when requested',
    'Device control capabilities (lock/unlock)',
    'Data collection and storage',
    'Emergency monitoring and response',
  ];

  @override
  void dispose() {
    _signatureController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _submitConsent() async {
    final l10n = AppLocalizations.of(context)!;
    
    // Validate all consent items are checked
    if (!_hasReadTerms || !_hasReadPrivacy || !_agreeToMonitoring || 
        !_understandDataCollection || !_isAdult) {
      setState(() {
        _errorMessage = l10n.allConsentItemsRequired;
      });
      return;
    }

    // Validate signature exists
    if (_signatureController.isEmpty) {
      setState(() {
        _errorMessage = l10n.signatureRequired;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Export signature as image
      final Uint8List? signature = await _signatureController.toPngBytes();
      if (signature == null) {
        throw Exception(l10n.signatureExportFailed);
      }

      // Prepare consent data
      final consentData = {
        'timestamp': DateTime.now().toIso8601String(),
        'consent_version': '1.0',
        'user_declared_adult': _isAdult,
        'terms_read': _hasReadTerms,
        'privacy_read': _hasReadPrivacy,
        'monitoring_agreed': _agreeToMonitoring,
        'data_collection_understood': _understandDataCollection,
        'consent_items': _consentItems,
        'device_info': {
          'platform': Theme.of(context).platform.name,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
        'legal_basis': 'explicit_consent',
        'consent_method': 'digital_signature',
      };

      widget.onConsentGiven(signature, consentData);

    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _clearSignature() {
    setState(() {
      _signatureController.clear();
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.digitalConsent),
        leading: widget.onCancel != null 
          ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: widget.onCancel,
            )
          : null,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Debug test
                  const Text('DEBUG: Content loading...'),
                  const SizedBox(height: 16),
                  
                  // Header section
                  Text(
                    l10n.consentFormTitle,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Text(
                    l10n.consentFormDescription,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),

                  // Monitoring capabilities section
                  _buildSection(
                    title: l10n.monitoringCapabilities,
                    children: [
                      Text(
                        l10n.monitoringCapabilitiesDescription,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      ..._consentItems.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_outline, 
                                 size: 20, 
                                 color: Theme.of(context).primaryColor),
                            const SizedBox(width: 8),
                            Expanded(child: Text(item)),
                          ],
                        ),
                      )),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Data handling section
                  _buildSection(
                    title: l10n.dataHandling,
                    children: [
                      Text(l10n.dataHandlingDescription),
                      const SizedBox(height: 8),
                      Text(l10n.dataRetentionInfo),
                      const SizedBox(height: 8),
                      Text(l10n.dataSecurityInfo),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Rights section
                  _buildSection(
                    title: l10n.yourRights,
                    children: [
                      Text(l10n.rightsDescription),
                      const SizedBox(height: 8),
                      Text(l10n.withdrawalRights),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Consent checkboxes
                  _buildConsentCheckboxes(l10n),

                  const SizedBox(height: 24),

                  // Signature section
                  _buildSignatureSection(l10n),

                  const SizedBox(height: 24),

                  // Error message
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, 
                               color: Theme.of(context).colorScheme.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 100), // Space for floating button
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: FloatingActionButton.extended(
          onPressed: _isLoading ? null : _submitConsent,
          backgroundColor: _canSubmit() 
            ? Theme.of(context).primaryColor 
            : Theme.of(context).disabledColor,
          icon: _isLoading 
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.onPrimary,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.check),
          label: Text(_isLoading ? l10n.processing : l10n.giveConsent),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildConsentCheckboxes(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.consentConfirmation,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            CheckboxListTile(
              title: Text(l10n.confirmAdultStatus),
              subtitle: Text(l10n.confirmAdultStatusDescription),
              value: _isAdult,
              onChanged: (value) => setState(() => _isAdult = value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            
            CheckboxListTile(
              title: Text(l10n.confirmReadTerms),
              subtitle: TextButton(
                onPressed: () => _showTermsDialog(context),
                child: Text(l10n.viewTermsOfService),
              ),
              value: _hasReadTerms,
              onChanged: (value) => setState(() => _hasReadTerms = value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            
            CheckboxListTile(
              title: Text(l10n.confirmReadPrivacy),
              subtitle: TextButton(
                onPressed: () => _showPrivacyDialog(context),
                child: Text(l10n.viewPrivacyPolicy),
              ),
              value: _hasReadPrivacy,
              onChanged: (value) => setState(() => _hasReadPrivacy = value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            
            CheckboxListTile(
              title: Text(l10n.confirmMonitoringConsent),
              subtitle: Text(l10n.confirmMonitoringConsentDescription),
              value: _agreeToMonitoring,
              onChanged: (value) => setState(() => _agreeToMonitoring = value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            
            CheckboxListTile(
              title: Text(l10n.confirmDataCollection),
              subtitle: Text(l10n.confirmDataCollectionDescription),
              value: _understandDataCollection,
              onChanged: (value) => setState(() => _understandDataCollection = value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignatureSection(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.digitalSignature,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.signatureInstructions,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Signature(
                  controller: _signatureController,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  onPressed: _clearSignature,
                  icon: const Icon(Icons.clear),
                  label: Text(l10n.clearSignature),
                ),
                
                Flexible(
                  child: Text(
                    l10n.signatureDate(DateTime.now().toString().split(' ')[0]),
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _canSubmit() {
    return _hasReadTerms && 
           _hasReadPrivacy && 
           _agreeToMonitoring && 
           _understandDataCollection && 
           _isAdult && 
           _signatureController.isNotEmpty;
  }

  void _showTermsDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.termsOfService),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Text(l10n.termsOfServiceContent),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.privacyPolicy),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Text(l10n.privacyPolicyContent),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }
}