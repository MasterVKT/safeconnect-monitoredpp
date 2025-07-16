import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:monitored_app/app/routes.dart';
import 'package:monitored_app/app/theme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  int _currentStep = 0;
  
  final List<Map<String, dynamic>> _permissions = [
    {
      'type': Permission.location,
      'title': 'locationPermission',
      'description': 'locationPermissionDescription',
      'icon': Icons.location_on,
      'status': PermissionStatus.denied,
      'required': true
    },
    {
      'type': Permission.sms,
      'title': 'smsPermission',
      'description': 'smsPermissionDescription',
      'icon': Icons.sms,
      'status': PermissionStatus.denied,
      'required': true
    },
    {
      'type': Permission.phone,
      'title': 'phonePermission',
      'description': 'phonePermissionDescription',
      'icon': Icons.call,
      'status': PermissionStatus.denied,
      'required': true
    },
    {
      'type': Permission.storage,
      'title': 'storagePermission',
      'description': 'storagePermissionDescription',
      'icon': Icons.storage,
      'status': PermissionStatus.denied,
      'required': true
    },
    {
      'type': Permission.camera,
      'title': 'cameraPermission',
      'description': 'cameraPermissionDescription',
      'icon': Icons.camera_alt,
      'status': PermissionStatus.denied,
      'required': false
    },
    {
      'type': Permission.microphone,
      'title': 'microphonePermission',
      'description': 'microphonePermissionDescription',
      'icon': Icons.mic,
      'status': PermissionStatus.denied,
      'required': false
    },
  ];
  
  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }
  
  Future<void> _checkPermissions() async {
    for (int i = 0; i < _permissions.length; i++) {
      final status = await _permissions[i]['type'].status;
      setState(() {
        _permissions[i]['status'] = status;
      });
    }
  }
  
  Future<void> _requestPermission(int index) async {
    final permission = _permissions[index]['type'];
    final status = await permission.request();
    
    setState(() {
      _permissions[index]['status'] = status;
    });
  }
  
  bool _canProceed() {
    // Check if all required permissions are granted
    for (final permission in _permissions) {
      if (permission['required'] && permission['status'] != PermissionStatus.granted) {
        return false;
      }
    }
    return true;
  }
  
  void _goToNextStep() {
    if (_currentStep < _permissions.length - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      // All permissions have been requested, move to next screen
      Navigator.pushReplacementNamed(context, AppRoutes.setupComplete);
    }
  }
  
  void _goToPreviousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.requiredPermissions),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentStep + 1) / _permissions.length,
            backgroundColor: Colors.grey[300],
            color: AppTheme.primaryColor,
          ),
          
          // Stepper content
          Expanded(
            child: Stepper(
              type: StepperType.horizontal,
              currentStep: _currentStep,
              onStepContinue: _goToNextStep,
              onStepCancel: _goToPreviousStep,
              controlsBuilder: (context, details) {
                final isCurrentPermissionGranted = 
                    _permissions[_currentStep]['status'] == PermissionStatus.granted;
                
                return Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Row(
                    children: [
                      ElevatedButton(
                        onPressed: isCurrentPermissionGranted 
                            ? details.onStepContinue 
                            : () => _requestPermission(_currentStep),
                        child: Text(
                          isCurrentPermissionGranted
                              ? l10n.continueText
                              : l10n.grantPermission
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (_currentStep > 0)
                        TextButton(
                          onPressed: details.onStepCancel,
                          child: Text(l10n.back),
                        ),
                    ],
                  ),
                );
              },
              steps: _permissions.map((permission) {
                final title = l10n.permissionTitle(permission['title']);
                final description = l10n.permissionDescription(permission['description']);
                final isGranted = permission['status'] == PermissionStatus.granted;
                
                return Step(
                  title: Text(title),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Permission icon
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: isGranted 
                                ? AppTheme.secondaryColor.withOpacity(0.1)
                                : AppTheme.primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            permission['icon'],
                            size: 40,
                            color: isGranted 
                                ? AppTheme.secondaryColor
                                : AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Permission description
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 12),
                      
                      // Required tag
                      if (permission['required'])
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.alertColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            l10n.requiredPermission,
                            style: const TextStyle(
                              color: AppTheme.alertColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      
                      // Permission status
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Icon(
                            isGranted ? Icons.check_circle : Icons.info_outline,
                            color: isGranted ? AppTheme.secondaryColor : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isGranted 
                                ? l10n.permissionGranted
                                : l10n.permissionRequired,
                            style: TextStyle(
                              color: isGranted ? AppTheme.secondaryColor : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  isActive: _currentStep == _permissions.indexOf(permission),
                  state: permission['status'] == PermissionStatus.granted
                      ? StepState.complete
                      : StepState.indexed,
                );
              }).toList(),
            ),
          ),
          
          // Bottom navigation bar with continue button
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _canProceed()
                        ? () => Navigator.pushReplacementNamed(context, AppRoutes.setupComplete)
                        : null,
                    child: Text(l10n.continueToSetup),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}