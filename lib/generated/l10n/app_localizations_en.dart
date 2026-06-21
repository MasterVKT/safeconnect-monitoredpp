// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'XP SafeConnect';

  @override
  String get welcomeToSafeConnect => 'Welcome to XP SafeConnect';

  @override
  String get pairingScreenDescription =>
      'Please enter the pairing code provided by the monitoring device to start the setup process.';

  @override
  String get pairingCode => 'Pairing Code';

  @override
  String get enterPairingCode => 'Enter the 6-digit code';

  @override
  String get pairingCodeRequired => 'Please enter the pairing code';

  @override
  String get continueText => 'Continue';

  @override
  String get cancel => 'Cancel';

  @override
  String get exitSetup => 'Exit Setup';

  @override
  String get exitSetupConfirmation =>
      'Are you sure you want to exit the setup? This will close the application.';

  @override
  String get exit => 'Exit';

  @override
  String get requiredPermissions => 'Required Permissions';

  @override
  String permissionTitle(String title) {
    return '$title';
  }

  @override
  String permissionDescription(String description) {
    return '$description';
  }

  @override
  String get locationPermission => 'Location';

  @override
  String get locationPermissionDescription =>
      'Allows tracking of your device\'s location in real-time. This is required for the monitoring device to see where you are.';

  @override
  String get smsPermission => 'SMS Messages';

  @override
  String get smsPermissionDescription =>
      'Allows access to SMS messages sent and received on this device.';

  @override
  String get phonePermission => 'Phone Calls';

  @override
  String get phonePermissionDescription =>
      'Allows monitoring of incoming and outgoing calls on this device.';

  @override
  String get storagePermission => 'Storage';

  @override
  String get storagePermissionDescription =>
      'Allows access to images and other files stored on this device.';

  @override
  String get cameraPermission => 'Camera';

  @override
  String get cameraPermissionDescription =>
      'Allows remote capture of photos using this device\'s camera when requested.';

  @override
  String get microphonePermission => 'Microphone';

  @override
  String get microphonePermissionDescription =>
      'Allows remote audio recording using this device\'s microphone when requested.';

  @override
  String get requiredPermission => 'Required';

  @override
  String get permissionGranted => 'Permission granted';

  @override
  String get permissionRequired => 'Permission required';

  @override
  String get grantPermission => 'Grant Permission';

  @override
  String get back => 'Back';

  @override
  String get continueToSetup => 'Continue to Setup';

  @override
  String get finalSetup => 'Final Setup';

  @override
  String get permissionsGranted => 'Permissions Granted!';

  @override
  String get displayMode => 'Display Mode';

  @override
  String get displayModeNormal => 'Normal';

  @override
  String get displayModeNormalDesc =>
      'The app icon and name will be visible in the app drawer.';

  @override
  String get displayModeDiscrete => 'Discrete';

  @override
  String get displayModeDiscreteDesc =>
      'The app will use a generic name and icon to avoid detection.';

  @override
  String get displayModeHidden => 'Hidden';

  @override
  String get displayModeHiddenDesc =>
      'The app will not appear in the app drawer (access via phone dial code).';

  @override
  String get autoStart => 'Auto-Start';

  @override
  String get autoStartDescription =>
      'Automatically start the app when the device boots up.';

  @override
  String get notificationMode => 'Notification Mode';

  @override
  String get notificationModeVisible => 'Visible';

  @override
  String get notificationModeVisibleDesc =>
      'Normal notifications with app name and icon.';

  @override
  String get notificationModeMinimized => 'Minimized';

  @override
  String get notificationModeMinimizedDesc =>
      'Compact notifications with minimal information.';

  @override
  String get notificationModeHidden => 'Hidden';

  @override
  String get notificationModeHiddenDesc =>
      'No visible notifications (background service only).';

  @override
  String get importantInfo => 'Important Information';

  @override
  String get backgroundServiceInfo =>
      'This app will run continuously in the background to provide monitoring capabilities. This may affect battery life. The background service will automatically restart if terminated.';

  @override
  String get finishSetup => 'Finish Setup';

  @override
  String get errorOccurred => 'Error Occurred';

  @override
  String get close => 'Close';

  @override
  String get settings => 'Settings';

  @override
  String get connected => 'Connected';

  @override
  String get disconnected => 'Disconnected';

  @override
  String connectedToDevice(String device) {
    return 'Connected to $device';
  }

  @override
  String get notConnectedToAnyDevice =>
      'Not connected to any monitoring device';

  @override
  String get monitoringStatus => 'Monitoring Status';

  @override
  String get locationTracking => 'Location Tracking';

  @override
  String get messageMonitoring => 'Message Monitoring';

  @override
  String get callsMonitoring => 'Calls Monitoring';

  @override
  String get appsMonitoring => 'Apps Monitoring';

  @override
  String get photosAccess => 'Photos Access';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get viewSharedData => 'View Shared Data';

  @override
  String get contactMonitor => 'Contact Monitor';

  @override
  String get featureComingSoon => 'This feature is coming soon';

  @override
  String get holdForEmergency => 'Hold for Emergency';

  @override
  String featureActiveAndSharing(String feature) {
    return '$feature is active and sharing data';
  }

  @override
  String featureNotActive(String feature) {
    return '$feature is not active';
  }

  @override
  String get sharedData => 'Shared Data';

  @override
  String get aboutSharedData => 'About Shared Data';

  @override
  String get sharedDataExplanation =>
      'This screen shows you what data is being shared with the monitoring device. You cannot disable these features as they are part of the monitoring agreement.';

  @override
  String get location => 'Location';

  @override
  String get messages => 'Messages';

  @override
  String get calls => 'Calls';

  @override
  String get apps => 'Apps';

  @override
  String get photos => 'Photos';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String lastSyncTime(String time) {
    return 'Last sync: $time';
  }

  @override
  String get viewPrivacyPolicy => 'View Privacy Policy';

  @override
  String get locationSharingDescription =>
      'Your current location is being shared with the monitoring device in real-time. This includes your GPS coordinates, accuracy, and movement speed.';

  @override
  String get messagesSharingDescription =>
      'Your SMS messages and some messaging apps content are being shared with the monitoring device.';

  @override
  String get callsSharingDescription =>
      'Information about your incoming and outgoing calls is being shared, including the phone number, contact name, and call duration.';

  @override
  String get appsSharingDescription =>
      'Information about apps you use and how long you use them is being shared with the monitoring device.';

  @override
  String get photosSharingDescription =>
      'Photos access is currently not enabled on this device.';

  @override
  String get emergencyMode => 'Emergency Mode';

  @override
  String get emergencyModeActive => 'EMERGENCY MODE ACTIVE';

  @override
  String get emergencyModeDescription =>
      'In an emergency situation, tap the button below to alert the monitoring device. They will be notified immediately and can take appropriate action.';

  @override
  String get tapToActivate => 'Tap to Activate';

  @override
  String get emergencyModeWarning =>
      'Only use this in case of a genuine emergency. False alarms may result in restriction of this feature.';

  @override
  String activatingEmergencyIn(String seconds) {
    return 'Activating emergency mode in ${seconds}s';
  }

  @override
  String get cancelEmergency => 'Cancel';

  @override
  String get tapToCancelEmergency => 'Tap to cancel emergency activation';

  @override
  String get emergencyModeActivated => 'Emergency Mode Activated';

  @override
  String get monitoringDeviceNotified =>
      'The monitoring device has been notified of your emergency situation.';

  @override
  String get emergencyActions => 'Emergency Actions';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get recordAudio => 'Record Audio';

  @override
  String get sendMessage => 'Send Message';

  @override
  String get deactivateEmergencyMode => 'Deactivate Emergency Mode';

  @override
  String get justNow => 'just now';

  @override
  String minutesAgo(String minutes) {
    return '$minutes minutes ago';
  }

  @override
  String hoursAgo(String hours) {
    return '$hours hours ago';
  }

  @override
  String daysAgo(String days) {
    return '$days days ago';
  }

  @override
  String get remoteUnlockRequested => 'Remote unlock requested';

  @override
  String get deviceUnlocked => 'Device unlocked';

  @override
  String get unlockPermissionRequired =>
      'This application needs permission to unlock your device';

  @override
  String get scanQRCode => 'Scan QR Code';

  @override
  String get qrScanInstructions =>
      'Position the QR code within the frame to scan it';

  @override
  String get enterCodeManually => 'Enter code manually';

  @override
  String get invalidQRCode => 'Invalid QR code format';

  @override
  String get error => 'Error';

  @override
  String get ok => 'OK';

  @override
  String get confirm => 'Confirm';

  @override
  String get digitalConsent => 'Digital Consent';

  @override
  String get consentFormTitle => 'Monitoring Consent Agreement';

  @override
  String get consentFormDescription =>
      'This application will monitor and collect data from this device. Please read the following information carefully and provide your explicit consent.';

  @override
  String get monitoringCapabilities => 'Monitoring Capabilities';

  @override
  String get monitoringCapabilitiesDescription =>
      'This application will collect the following types of data:';

  @override
  String get dataHandling => 'Data Handling';

  @override
  String get dataHandlingDescription =>
      'All collected data is encrypted and transmitted securely to authorized monitoring devices only.';

  @override
  String get dataRetentionInfo =>
      'Data is retained according to your monitoring agreement and applicable privacy laws.';

  @override
  String get dataSecurityInfo =>
      'We implement industry-standard security measures to protect your data.';

  @override
  String get yourRights => 'Your Rights';

  @override
  String get rightsDescription =>
      'You have the right to access, modify, or delete your personal data at any time.';

  @override
  String get withdrawalRights =>
      'You can withdraw this consent at any time by contacting the monitoring administrator.';

  @override
  String get consentConfirmation => 'Consent Confirmation';

  @override
  String get confirmAdultStatus => 'I confirm that I am at least 18 years old';

  @override
  String get confirmAdultStatusDescription =>
      'You must be an adult to provide legal consent';

  @override
  String get confirmReadTerms =>
      'I have read and agree to the Terms of Service';

  @override
  String get confirmReadPrivacy =>
      'I have read and understand the Privacy Policy';

  @override
  String get confirmMonitoringConsent =>
      'I consent to monitoring of this device';

  @override
  String get confirmMonitoringConsentDescription =>
      'This includes all data collection activities listed above';

  @override
  String get confirmDataCollection =>
      'I understand how my data will be collected and used';

  @override
  String get confirmDataCollectionDescription =>
      'Including storage, processing, and sharing with authorized parties';

  @override
  String get digitalSignature => 'Digital Signature';

  @override
  String get signatureInstructions =>
      'Please sign below to provide your legal consent:';

  @override
  String get clearSignature => 'Clear';

  @override
  String signatureDate(String date) {
    return 'Date: $date';
  }

  @override
  String get giveConsent => 'Give Consent';

  @override
  String get processing => 'Processing...';

  @override
  String get allConsentItemsRequired =>
      'Please check all consent items before proceeding';

  @override
  String get signatureRequired => 'Please provide your digital signature';

  @override
  String get signatureExportFailed => 'Failed to export signature';

  @override
  String get viewTermsOfService => 'View Terms of Service';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsOfServiceContent =>
      'These terms govern your use of the XP SafeConnect monitoring application. By using this application, you agree to be monitored according to the capabilities described in this consent form. The monitoring is conducted for legitimate purposes such as parental control, family safety, or authorized workplace monitoring. You acknowledge that the data collected will be shared with authorized monitoring devices and may be used for safety, security, and compliance purposes.';

  @override
  String get privacyPolicyContent =>
      'Your privacy is important to us. This application collects location data, communication logs, application usage, and other device information for monitoring purposes. All data is encrypted during transmission and storage. Access to your data is limited to authorized monitoring administrators. You have the right to request access to your data, correction of inaccurate data, or deletion of your data subject to legal and safety requirements.';

  @override
  String get processingConsent => 'Processing Consent';

  @override
  String get pleaseWait => 'Please wait while we process your consent...';

  @override
  String get essentialPermissions => 'Essential Permissions';

  @override
  String get monitoringPermissions => 'Monitoring Permissions';

  @override
  String get advancedPermissions => 'Advanced Permissions';

  @override
  String get optionalPermissions => 'Optional Permissions';

  @override
  String get checkingPermissions => 'Checking Permissions';

  @override
  String get noPermissionsToRequest => 'No permissions to request';

  @override
  String permissionStep(String current, String total) {
    return 'Step $current of $total';
  }

  @override
  String get whyThisPermission => 'Why this permission?';

  @override
  String get requiredPermissionWarning =>
      'This permission is required for the app to function properly';

  @override
  String get troubleshootingSteps => 'Troubleshooting Steps';

  @override
  String get needHelp => 'Need Help?';

  @override
  String get hideTroubleshooting => 'Hide Help';

  @override
  String get skipOptional => 'Skip (Optional)';

  @override
  String get accessibilityPermission => 'Accessibility Service';

  @override
  String get accessibilityPermissionDescription =>
      'Allows monitoring of app usage and messaging';

  @override
  String get accessibilityPermissionDetailed =>
      'The accessibility service is required to monitor app usage, detect messaging activity, and provide comprehensive device monitoring. This is essential for the monitoring functionality to work properly.';

  @override
  String get usageStatsPermission => 'Usage Statistics';

  @override
  String get usageStatsPermissionDescription =>
      'Tracks which apps are used and for how long';

  @override
  String get usageStatsPermissionDetailed =>
      'Usage statistics permission allows the app to track which applications are opened, how long they are used, and when they are closed. This data is essential for comprehensive device monitoring.';

  @override
  String get deviceAdminPermission => 'Device Administrator';

  @override
  String get deviceAdminPermissionDescription =>
      'Allows remote device control and anti-tamper protection';

  @override
  String get deviceAdminPermissionDetailed =>
      'Device administrator privileges enable remote locking/unlocking, prevent unauthorized uninstallation, and provide enhanced security features. This is optional but recommended for full functionality.';

  @override
  String get batteryOptimizationPermission => 'Battery Optimization';

  @override
  String get batteryOptimizationPermissionDescription =>
      'Prevents the app from being killed by power management';

  @override
  String get batteryOptimizationPermissionDetailed =>
      'Disabling battery optimization ensures the app continues running in the background for continuous monitoring. This prevents Android\'s power management from stopping the monitoring service.';

  @override
  String get locationPermissionDetailed =>
      'Location access is required for real-time GPS tracking. The app needs \'Allow all the time\' permission to track location even when the app is not actively being used.';

  @override
  String get phonePermissionDetailed =>
      'Phone permission allows monitoring of incoming and outgoing calls, including call duration, contact information, and call state. This is essential for call monitoring features.';

  @override
  String get smsPermissionDetailed =>
      'SMS permission enables monitoring of text messages, including reading incoming messages and tracking messaging activity. This is required for comprehensive communication monitoring.';

  @override
  String get cameraPermissionDetailed =>
      'Camera access allows remote photo capture when requested by the monitoring device. This enables safety features like emergency photo capture.';

  @override
  String get microphonePermissionDetailed =>
      'Microphone access enables remote audio recording capabilities when requested by the monitoring device. This supports emergency monitoring and safety features.';

  @override
  String get notificationPermissionDetailed =>
      'Notification permission allows the app to show important alerts, status updates, and emergency notifications. This ensures you stay informed about the monitoring status.';

  @override
  String get permissionSummary => 'Permission Summary';

  @override
  String get permissionsConfigured => 'Permissions Configured!';

  @override
  String get permissionsPartiallyConfigured =>
      'Permissions Partially Configured';

  @override
  String permissionsGrantedSummary(String granted, String total) {
    return '$granted of $total permissions granted';
  }

  @override
  String get permissionStatusDetails => 'Permission Status Details';

  @override
  String get granted => 'Granted';

  @override
  String get notGranted => 'Not Granted';

  @override
  String get incompletePermissionsWarning => 'Some permissions are missing';

  @override
  String get incompletePermissionsDescription =>
      'The app may not function fully without all required permissions. You can continue with limited functionality or return to grant the missing permissions.';

  @override
  String get reviewPermissions => 'Review Permissions';

  @override
  String get continueAnyway => 'Continue Anyway';

  @override
  String get notificationPermission => 'Notifications';

  @override
  String get notificationPermissionDescription =>
      'Allows the app to display notifications';

  @override
  String get mediaPermissions => 'Media Permissions';

  @override
  String get systemPermissions => 'System Permissions';

  @override
  String get whyDoWeNeedThis => 'Why do we need this?';

  @override
  String permissionExplanation(String explanation) {
    return '$explanation';
  }

  @override
  String get locationAlwaysPermission => 'Background Location';

  @override
  String get locationAlwaysPermissionDescription =>
      'Allows location tracking even when the app is not open';

  @override
  String get locationAlwaysPermissionExplanation =>
      'Background location access is required for continuous location tracking. This ensures the monitoring device can always know your location for safety purposes.';

  @override
  String get locationPermissionExplanation =>
      'Location access is required for real-time GPS tracking. The app needs location permission to track your position for safety and monitoring purposes.';

  @override
  String get smsPermissionExplanation =>
      'SMS permission enables monitoring of text messages, including reading incoming messages and tracking messaging activity. This is required for comprehensive communication monitoring.';

  @override
  String get phonePermissionExplanation =>
      'Phone permission allows monitoring of incoming and outgoing calls, including call duration, contact information, and call state. This is essential for call monitoring features.';

  @override
  String get usageStatsPermissionExplanation =>
      'Usage statistics permission allows the app to track which applications are opened, how long they are used, and when they are closed. This data is essential for comprehensive device monitoring.';

  @override
  String get accessibilityServicePermissionExplanation =>
      'The accessibility service is required to monitor app usage, detect messaging activity, and provide comprehensive device monitoring. This is essential for the monitoring functionality to work properly.';

  @override
  String get cameraPermissionExplanation =>
      'Camera access allows remote photo capture when requested by the monitoring device. This enables safety features like emergency photo capture.';

  @override
  String get microphonePermissionExplanation =>
      'Microphone access enables remote audio recording capabilities when requested by the monitoring device. This supports emergency monitoring and safety features.';

  @override
  String get storagePermissionExplanation =>
      'Storage permission allows access to files and media on your device. This is needed to save monitoring data and access device content when required.';

  @override
  String get deviceAdminPermissionExplanation =>
      'Device administrator privileges enable remote locking/unlocking, prevent unauthorized uninstallation, and provide enhanced security features. This is optional but recommended for full functionality.';

  @override
  String get batteryOptimizationPermissionExplanation =>
      'Disabling battery optimization ensures the app continues running in the background for continuous monitoring. This prevents Android\'s power management from stopping the monitoring service.';

  @override
  String get notificationPermissionExplanation =>
      'Notification permission allows the app to show important alerts, status updates, and emergency notifications. This ensures you stay informed about the monitoring status.';

  @override
  String get optionalPermission => 'Optional';

  @override
  String get skip => 'Skip';

  @override
  String get completeSetup => 'Complete Setup';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get permissionDenied => 'Permission Denied';

  @override
  String get permissionPermanentlyDeniedMessage =>
      'This permission has been permanently denied. You can grant it manually in the app settings.';

  @override
  String get incompleteSetup => 'Incomplete Setup';

  @override
  String get requiredPermissionsMissing =>
      'Some required permissions are still missing:';

  @override
  String get p2pConnectionStatus => 'P2P Connection Status';

  @override
  String get addConnection => 'Add Connection';

  @override
  String get activeConnections => 'Active Connections';

  @override
  String get noActiveConnections => 'No active connections';

  @override
  String get p2pUninitialized => 'Not initialized';

  @override
  String get p2pInitializing => 'Initializing...';

  @override
  String get p2pReady => 'Ready for connections';

  @override
  String p2pConnectedDevices(String count) {
    return '$count devices connected';
  }

  @override
  String get p2pConnecting => 'Connecting...';

  @override
  String get p2pConnected => 'Connected';

  @override
  String get p2pDisconnected => 'Disconnected';

  @override
  String get p2pError => 'Connection error';

  @override
  String get connectToDevice => 'Connect to Device';

  @override
  String get deviceId => 'Device ID';

  @override
  String get enterDeviceId => 'Enter device ID';

  @override
  String get p2pConnectionInfo =>
      'Enter the device ID of the monitoring device you want to connect to directly.';

  @override
  String get connect => 'Connect';

  @override
  String get connectingToDevice => 'Connecting to device...';

  @override
  String get connectionSuccessful => 'Connection successful';

  @override
  String get connectionFailed => 'Connection failed';

  @override
  String get connectionError => 'Connection error occurred';

  @override
  String get connectedAt => 'Connected at';

  @override
  String get sendCommand => 'Send Command';

  @override
  String get sendFile => 'Send File';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get lockDevice => 'Lock Device';

  @override
  String get unlockDevice => 'Unlock Device';

  @override
  String get restartDevice => 'Restart Device';

  @override
  String get capturePhoto => 'Capture Photo';

  @override
  String get commandSent => 'Command sent successfully';

  @override
  String get commandFailed => 'Command failed';

  @override
  String get commandError => 'Error sending command';

  @override
  String get confirmDisconnection => 'Confirm Disconnection';

  @override
  String disconnectDeviceConfirmation(String deviceName) {
    return 'Are you sure you want to disconnect from $deviceName?';
  }

  @override
  String get deviceDisconnected => 'Device disconnected';

  @override
  String get disconnectionFailed => 'Disconnection failed';

  @override
  String get invalidPairingCodeFormat =>
      'The pairing code must contain 6 digits';

  @override
  String get pairingFailed => 'Pairing failed';

  @override
  String get networkError => 'Network error';

  @override
  String get logoutConfirmation => 'Logout Confirmation';

  @override
  String get logoutConfirmationMessage =>
      'Are you sure you want to logout? The application will be closed and will need to be paired again.';

  @override
  String get logout => 'Logout';
}
