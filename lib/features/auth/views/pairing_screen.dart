import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monitored_app/app/routes.dart';
import 'package:monitored_app/app/theme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
  
  @override
  void initState() {
    super.initState();
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
    if (_pairingCodeController.text.isEmpty) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.pairingCodeRequired;
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // TODO: Implement actual pairing functionality with the API
      // For now, we'll simulate a successful pairing after a delay
      await Future.delayed(const Duration(seconds: 2));
      
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.permissions);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo
              Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 80,
                  // If you don't have this asset yet, use a placeholder
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 80,
                    width: 80,
                    color: AppTheme.primaryColor,
                    child: const Center(
                      child: Text(
                        'LOGO',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
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
              ElevatedButton(
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
              const SizedBox(height: 16),
              TextButton(
                onPressed: _isLoading ? null : () {
                  // TODO: Implement exit functionality - possibly closing the app
                  // For now, we'll just show a dialog
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
                            // In a real app, you would exit here
                          },
                          child: Text(l10n.exit),
                        ),
                      ],
                    ),
                  );
                },
                child: Text(l10n.cancel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}