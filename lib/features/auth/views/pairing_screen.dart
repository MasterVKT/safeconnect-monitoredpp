import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monitored_app/app/routes.dart';
import 'package:monitored_app/app/theme.dart';
import 'package:monitored_app/app/locator.dart';
import 'package:monitored_app/features/auth/widgets/qr_scanner.dart';
import 'package:monitored_app/features/auth/repositories/auth_repository.dart';
import 'package:monitored_app/core/services/auth_service.dart';
import 'package:monitored_app/generated/l10n/app_localizations.dart';

class PairingScreen extends ConsumerStatefulWidget {
  final String? pairingCode;

  const PairingScreen({
    super.key,
    this.pairingCode,
  });

  @override
  ConsumerState<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends ConsumerState<PairingScreen> {
  final TextEditingController _pairingCodeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  late final AuthRepository _authRepository;

  @override
  void initState() {
    super.initState();
    _authRepository = AuthRepository(locator<AuthService>());
    if (widget.pairingCode != null) {
      _pairingCodeController.text = widget.pairingCode!;
    }
  }

  @override
  void dispose() {
    _pairingCodeController.dispose();
    super.dispose();
  }

  Future<void> _validatePairingCode() async {
    final l10n = AppLocalizations.of(context)!;

    if (_pairingCodeController.text.isEmpty) {
      setState(() {
        _errorMessage = l10n.pairingCodeRequired;
      });
      return;
    }

    // Validate pairing code format (should be 6 digits)
    if (_pairingCodeController.text.length != 6 ||
        !RegExp(r'^\d{6}$').hasMatch(_pairingCodeController.text)) {
      setState(() {
        _errorMessage = l10n.invalidPairingCodeFormat;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint(
          'Starting device pairing with code: ${_pairingCodeController.text}');

      // Use the actual AuthRepository to pair the device
      final result =
          await _authRepository.pairDevice(_pairingCodeController.text);

      if (!context.mounted) return;

      result.when(
        success: (user) {
          debugPrint('Device pairing successful');
          Navigator.pushReplacementNamed(context, AppRoutes.consent);
        },
        error: (message, errorCode) {
          setState(() {
            _errorMessage = message;
          });
          debugPrint('Device pairing failed: $message');
        },
      );
    } catch (e) {
      if (!context.mounted) return;

      setState(() {
        _errorMessage = '${l10n.networkError}: $e';
      });
      debugPrint('Error during device pairing: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _openQRScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRScannerWidget(
          onCodeScanned: (String code) {
            Navigator.pop(context);
            setState(() {
              _pairingCodeController.text = code;
            });
            // Automatically validate the scanned code
            _validatePairingCode();
          },
          onClose: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _showExitDialog() {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.exitSetup),
        content: Text(l10n.exitSetupConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Close the app properly
              SystemNavigator.pop();
            },
            child: Text(l10n.exit),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo placeholder to avoid missing-asset crashes during setup.
                  Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      color: Colors.white,
                      size: 42,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Welcome message
                  Text(
                    l10n.welcomeToSafeConnect,
                    style: Theme.of(context).textTheme.displayLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  Text(
                    l10n.pairingScreenDescription,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // Pairing code input
                  TextField(
                    controller: _pairingCodeController,
                    decoration: InputDecoration(
                      labelText: l10n.pairingCode,
                      hintText: l10n.enterPairingCode,
                      errorText: _errorMessage,
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, letterSpacing: 8),
                  ),
                  const SizedBox(height: 24),

                  // Action buttons
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _validatePairingCode,
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Theme.of(context).colorScheme.onPrimary,
                                strokeWidth: 3,
                              ),
                            )
                          : Text(l10n.continueText),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // QR Code Scanner button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _openQRScanner,
                      icon: const Icon(Icons.qr_code_scanner),
                      label: Text(l10n.scanQRCode),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _isLoading ? null : () => _showExitDialog(),
                    child: Text(l10n.cancel),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
