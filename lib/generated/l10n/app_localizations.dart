import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('fr'),
    Locale('en')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'XP SafeConnect'**
  String get appName;

  /// No description provided for @welcomeToSafeConnect.
  ///
  /// In en, this message translates to:
  /// **'Welcome to XP SafeConnect'**
  String get welcomeToSafeConnect;

  /// No description provided for @pairingScreenDescription.
  ///
  /// In en, this message translates to:
  /// **'Please enter the pairing code provided by the monitoring device to start the setup process.'**
  String get pairingScreenDescription;

  /// No description provided for @pairingCode.
  ///
  /// In en, this message translates to:
  /// **'Pairing Code'**
  String get pairingCode;

  /// No description provided for @enterPairingCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code'**
  String get enterPairingCode;

  /// No description provided for @pairingCodeRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter the pairing code'**
  String get pairingCodeRequired;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @exitSetup.
  ///
  /// In en, this message translates to:
  /// **'Exit Setup'**
  String get exitSetup;

  /// No description provided for @exitSetupConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to exit the setup? This will close the application.'**
  String get exitSetupConfirmation;

  /// No description provided for @exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// No description provided for @requiredPermissions.
  ///
  /// In en, this message translates to:
  /// **'Required Permissions'**
  String get requiredPermissions;

  /// No description provided for @permissionTitle.
  ///
  /// In en, this message translates to:
  /// **'{title}'**
  String permissionTitle(String title);

  /// No description provided for @permissionDescription.
  ///
  /// In en, this message translates to:
  /// **'{description}'**
  String permissionDescription(String description);

  /// No description provided for @locationPermission.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationPermission;

  /// No description provided for @locationPermissionDescription.
  ///
  /// In en, this message translates to:
  /// **'Allows tracking of your device\'s location in real-time. This is required for the monitoring device to see where you are.'**
  String get locationPermissionDescription;

  /// No description provided for @smsPermission.
  ///
  /// In en, this message translates to:
  /// **'SMS Messages'**
  String get smsPermission;

  /// No description provided for @smsPermissionDescription.
  ///
  /// In en, this message translates to:
  /// **'Allows access to SMS messages sent and received on this device.'**
  String get smsPermissionDescription;

  /// No description provided for @phonePermission.
  ///
  /// In en, this message translates to:
  /// **'Phone Calls'**
  String get phonePermission;

  /// No description provided for @phonePermissionDescription.
  ///
  /// In en, this message translates to:
  /// **'Allows monitoring of incoming and outgoing calls on this device.'**
  String get phonePermissionDescription;

  /// No description provided for @storagePermission.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storagePermission;

  /// No description provided for @storagePermissionDescription.
  ///
  /// In en, this message translates to:
  /// **'Allows access to images and other files stored on this device.'**
  String get storagePermissionDescription;

  /// No description provided for @cameraPermission.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get cameraPermission;

  /// No description provided for @cameraPermissionDescription.
  ///
  /// In en, this message translates to:
  /// **'Allows remote capture of photos using this device\'s camera when requested.'**
  String get cameraPermissionDescription;

  /// No description provided for @microphonePermission.
  ///
  /// In en, this message translates to:
  /// **'Microphone'**
  String get microphonePermission;

  /// No description provided for @microphonePermissionDescription.
  ///
  /// In en, this message translates to:
  /// **'Allows remote audio recording using this device\'s microphone when requested.'**
  String get microphonePermissionDescription;

  /// No description provided for @requiredPermission.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredPermission;

  /// No description provided for @permissionGranted.
  ///
  /// In en, this message translates to:
  /// **'Permission granted'**
  String get permissionGranted;

  /// No description provided for @permissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Permission required'**
  String get permissionRequired;

  /// No description provided for @grantPermission.
  ///
  /// In en, this message translates to:
  /// **'Grant Permission'**
  String get grantPermission;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @continueToSetup.
  ///
  /// In en, this message translates to:
  /// **'Continue to Setup'**
  String get continueToSetup;

  /// No description provided for @finalSetup.
  ///
  /// In en, this message translates to:
  /// **'Final Setup'**
  String get finalSetup;

  /// No description provided for @permissionsGranted.
  ///
  /// In en, this message translates to:
  /// **'Permissions Granted!'**
  String get permissionsGranted;

  /// No description provided for @displayMode.
  ///
  /// In en, this message translates to:
  /// **'Display Mode'**
  String get displayMode;

  /// No description provided for @displayModeNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get displayModeNormal;

  /// No description provided for @displayModeNormalDesc.
  ///
  /// In en, this message translates to:
  /// **'The app icon and name will be visible in the app drawer.'**
  String get displayModeNormalDesc;

  /// No description provided for @displayModeDiscrete.
  ///
  /// In en, this message translates to:
  /// **'Discrete'**
  String get displayModeDiscrete;

  /// No description provided for @displayModeDiscreteDesc.
  ///
  /// In en, this message translates to:
  /// **'The app will use a generic name and icon to avoid detection.'**
  String get displayModeDiscreteDesc;

  /// No description provided for @displayModeHidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get displayModeHidden;

  /// No description provided for @displayModeHiddenDesc.
  ///
  /// In en, this message translates to:
  /// **'The app will not appear in the app drawer (access via phone dial code).'**
  String get displayModeHiddenDesc;

  /// No description provided for @autoStart.
  ///
  /// In en, this message translates to:
  /// **'Auto-Start'**
  String get autoStart;

  /// No description provided for @autoStartDescription.
  ///
  /// In en, this message translates to:
  /// **'Automatically start the app when the device boots up.'**
  String get autoStartDescription;

  /// No description provided for @notificationMode.
  ///
  /// In en, this message translates to:
  /// **'Notification Mode'**
  String get notificationMode;

  /// No description provided for @notificationModeVisible.
  ///
  /// In en, this message translates to:
  /// **'Visible'**
  String get notificationModeVisible;

  /// No description provided for @notificationModeVisibleDesc.
  ///
  /// In en, this message translates to:
  /// **'Normal notifications with app name and icon.'**
  String get notificationModeVisibleDesc;

  /// No description provided for @notificationModeMinimized.
  ///
  /// In en, this message translates to:
  /// **'Minimized'**
  String get notificationModeMinimized;

  /// No description provided for @notificationModeMinimizedDesc.
  ///
  /// In en, this message translates to:
  /// **'Compact notifications with minimal information.'**
  String get notificationModeMinimizedDesc;

  /// No description provided for @notificationModeHidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get notificationModeHidden;

  /// No description provided for @notificationModeHiddenDesc.
  ///
  /// In en, this message translates to:
  /// **'No visible notifications (background service only).'**
  String get notificationModeHiddenDesc;

  /// No description provided for @importantInfo.
  ///
  /// In en, this message translates to:
  /// **'Important Information'**
  String get importantInfo;

  /// No description provided for @backgroundServiceInfo.
  ///
  /// In en, this message translates to:
  /// **'This app will run continuously in the background to provide monitoring capabilities. This may affect battery life. The background service will automatically restart if terminated.'**
  String get backgroundServiceInfo;

  /// No description provided for @finishSetup.
  ///
  /// In en, this message translates to:
  /// **'Finish Setup'**
  String get finishSetup;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'Error Occurred'**
  String get errorOccurred;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @disconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get disconnected;

  /// No description provided for @connectedToDevice.
  ///
  /// In en, this message translates to:
  /// **'Connected to {device}'**
  String connectedToDevice(String device);

  /// No description provided for @notConnectedToAnyDevice.
  ///
  /// In en, this message translates to:
  /// **'Not connected to any monitoring device'**
  String get notConnectedToAnyDevice;

  /// No description provided for @monitoringStatus.
  ///
  /// In en, this message translates to:
  /// **'Monitoring Status'**
  String get monitoringStatus;

  /// No description provided for @locationTracking.
  ///
  /// In en, this message translates to:
  /// **'Location Tracking'**
  String get locationTracking;

  /// No description provided for @messageMonitoring.
  ///
  /// In en, this message translates to:
  /// **'Message Monitoring'**
  String get messageMonitoring;

  /// No description provided for @callsMonitoring.
  ///
  /// In en, this message translates to:
  /// **'Calls Monitoring'**
  String get callsMonitoring;

  /// No description provided for @appsMonitoring.
  ///
  /// In en, this message translates to:
  /// **'Apps Monitoring'**
  String get appsMonitoring;

  /// No description provided for @photosAccess.
  ///
  /// In en, this message translates to:
  /// **'Photos Access'**
  String get photosAccess;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @viewSharedData.
  ///
  /// In en, this message translates to:
  /// **'View Shared Data'**
  String get viewSharedData;

  /// No description provided for @contactMonitor.
  ///
  /// In en, this message translates to:
  /// **'Contact Monitor'**
  String get contactMonitor;

  /// No description provided for @featureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'This feature is coming soon'**
  String get featureComingSoon;

  /// No description provided for @holdForEmergency.
  ///
  /// In en, this message translates to:
  /// **'Hold for Emergency'**
  String get holdForEmergency;

  /// No description provided for @featureActiveAndSharing.
  ///
  /// In en, this message translates to:
  /// **'{feature} is active and sharing data'**
  String featureActiveAndSharing(String feature);

  /// No description provided for @featureNotActive.
  ///
  /// In en, this message translates to:
  /// **'{feature} is not active'**
  String featureNotActive(String feature);

  /// No description provided for @sharedData.
  ///
  /// In en, this message translates to:
  /// **'Shared Data'**
  String get sharedData;

  /// No description provided for @aboutSharedData.
  ///
  /// In en, this message translates to:
  /// **'About Shared Data'**
  String get aboutSharedData;

  /// No description provided for @sharedDataExplanation.
  ///
  /// In en, this message translates to:
  /// **'This screen shows you what data is being shared with the monitoring device. You cannot disable these features as they are part of the monitoring agreement.'**
  String get sharedDataExplanation;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @calls.
  ///
  /// In en, this message translates to:
  /// **'Calls'**
  String get calls;

  /// No description provided for @apps.
  ///
  /// In en, this message translates to:
  /// **'Apps'**
  String get apps;

  /// No description provided for @photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @lastSyncTime.
  ///
  /// In en, this message translates to:
  /// **'Last sync: {time}'**
  String lastSyncTime(String time);

  /// No description provided for @viewPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'View Privacy Policy'**
  String get viewPrivacyPolicy;

  /// No description provided for @locationSharingDescription.
  ///
  /// In en, this message translates to:
  /// **'Your current location is being shared with the monitoring device in real-time. This includes your GPS coordinates, accuracy, and movement speed.'**
  String get locationSharingDescription;

  /// No description provided for @messagesSharingDescription.
  ///
  /// In en, this message translates to:
  /// **'Your SMS messages and some messaging apps content are being shared with the monitoring device.'**
  String get messagesSharingDescription;

  /// No description provided for @callsSharingDescription.
  ///
  /// In en, this message translates to:
  /// **'Information about your incoming and outgoing calls is being shared, including the phone number, contact name, and call duration.'**
  String get callsSharingDescription;

  /// No description provided for @appsSharingDescription.
  ///
  /// In en, this message translates to:
  /// **'Information about apps you use and how long you use them is being shared with the monitoring device.'**
  String get appsSharingDescription;

  /// No description provided for @photosSharingDescription.
  ///
  /// In en, this message translates to:
  /// **'Photos access is currently not enabled on this device.'**
  String get photosSharingDescription;

  /// No description provided for @emergencyMode.
  ///
  /// In en, this message translates to:
  /// **'Emergency Mode'**
  String get emergencyMode;

  /// No description provided for @emergencyModeActive.
  ///
  /// In en, this message translates to:
  /// **'EMERGENCY MODE ACTIVE'**
  String get emergencyModeActive;

  /// No description provided for @emergencyModeDescription.
  ///
  /// In en, this message translates to:
  /// **'In an emergency situation, tap the button below to alert the monitoring device. They will be notified immediately and can take appropriate action.'**
  String get emergencyModeDescription;

  /// No description provided for @tapToActivate.
  ///
  /// In en, this message translates to:
  /// **'Tap to Activate'**
  String get tapToActivate;

  /// No description provided for @emergencyModeWarning.
  ///
  /// In en, this message translates to:
  /// **'Only use this in case of a genuine emergency. False alarms may result in restriction of this feature.'**
  String get emergencyModeWarning;

  /// No description provided for @activatingEmergencyIn.
  ///
  /// In en, this message translates to:
  /// **'Activating emergency mode in {seconds}s'**
  String activatingEmergencyIn(String seconds);

  /// No description provided for @cancelEmergency.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelEmergency;

  /// No description provided for @tapToCancelEmergency.
  ///
  /// In en, this message translates to:
  /// **'Tap to cancel emergency activation'**
  String get tapToCancelEmergency;

  /// No description provided for @emergencyModeActivated.
  ///
  /// In en, this message translates to:
  /// **'Emergency Mode Activated'**
  String get emergencyModeActivated;

  /// No description provided for @monitoringDeviceNotified.
  ///
  /// In en, this message translates to:
  /// **'The monitoring device has been notified of your emergency situation.'**
  String get monitoringDeviceNotified;

  /// No description provided for @emergencyActions.
  ///
  /// In en, this message translates to:
  /// **'Emergency Actions'**
  String get emergencyActions;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @recordAudio.
  ///
  /// In en, this message translates to:
  /// **'Record Audio'**
  String get recordAudio;

  /// No description provided for @sendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send Message'**
  String get sendMessage;

  /// No description provided for @deactivateEmergencyMode.
  ///
  /// In en, this message translates to:
  /// **'Deactivate Emergency Mode'**
  String get deactivateEmergencyMode;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes ago'**
  String minutesAgo(String minutes);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours} hours ago'**
  String hoursAgo(String hours);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days} days ago'**
  String daysAgo(String days);

  /// No description provided for @remoteUnlockRequested.
  ///
  /// In en, this message translates to:
  /// **'Remote unlock requested'**
  String get remoteUnlockRequested;

  /// No description provided for @deviceUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Device unlocked'**
  String get deviceUnlocked;

  /// No description provided for @unlockPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'This application needs permission to unlock your device'**
  String get unlockPermissionRequired;

  /// No description provided for @scanQRCode.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get scanQRCode;

  /// No description provided for @qrScanInstructions.
  ///
  /// In en, this message translates to:
  /// **'Position the QR code within the frame to scan it'**
  String get qrScanInstructions;

  /// No description provided for @enterCodeManually.
  ///
  /// In en, this message translates to:
  /// **'Enter code manually'**
  String get enterCodeManually;

  /// No description provided for @invalidQRCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid QR code format'**
  String get invalidQRCode;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @digitalConsent.
  ///
  /// In en, this message translates to:
  /// **'Digital Consent'**
  String get digitalConsent;

  /// No description provided for @consentFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Monitoring Consent Agreement'**
  String get consentFormTitle;

  /// No description provided for @consentFormDescription.
  ///
  /// In en, this message translates to:
  /// **'This application will monitor and collect data from this device. Please read the following information carefully and provide your explicit consent.'**
  String get consentFormDescription;

  /// No description provided for @monitoringCapabilities.
  ///
  /// In en, this message translates to:
  /// **'Monitoring Capabilities'**
  String get monitoringCapabilities;

  /// No description provided for @monitoringCapabilitiesDescription.
  ///
  /// In en, this message translates to:
  /// **'This application will collect the following types of data:'**
  String get monitoringCapabilitiesDescription;

  /// No description provided for @dataHandling.
  ///
  /// In en, this message translates to:
  /// **'Data Handling'**
  String get dataHandling;

  /// No description provided for @dataHandlingDescription.
  ///
  /// In en, this message translates to:
  /// **'All collected data is encrypted and transmitted securely to authorized monitoring devices only.'**
  String get dataHandlingDescription;

  /// No description provided for @dataRetentionInfo.
  ///
  /// In en, this message translates to:
  /// **'Data is retained according to your monitoring agreement and applicable privacy laws.'**
  String get dataRetentionInfo;

  /// No description provided for @dataSecurityInfo.
  ///
  /// In en, this message translates to:
  /// **'We implement industry-standard security measures to protect your data.'**
  String get dataSecurityInfo;

  /// No description provided for @yourRights.
  ///
  /// In en, this message translates to:
  /// **'Your Rights'**
  String get yourRights;

  /// No description provided for @rightsDescription.
  ///
  /// In en, this message translates to:
  /// **'You have the right to access, modify, or delete your personal data at any time.'**
  String get rightsDescription;

  /// No description provided for @withdrawalRights.
  ///
  /// In en, this message translates to:
  /// **'You can withdraw this consent at any time by contacting the monitoring administrator.'**
  String get withdrawalRights;

  /// No description provided for @consentConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Consent Confirmation'**
  String get consentConfirmation;

  /// No description provided for @confirmAdultStatus.
  ///
  /// In en, this message translates to:
  /// **'I confirm that I am at least 18 years old'**
  String get confirmAdultStatus;

  /// No description provided for @confirmAdultStatusDescription.
  ///
  /// In en, this message translates to:
  /// **'You must be an adult to provide legal consent'**
  String get confirmAdultStatusDescription;

  /// No description provided for @confirmReadTerms.
  ///
  /// In en, this message translates to:
  /// **'I have read and agree to the Terms of Service'**
  String get confirmReadTerms;

  /// No description provided for @confirmReadPrivacy.
  ///
  /// In en, this message translates to:
  /// **'I have read and understand the Privacy Policy'**
  String get confirmReadPrivacy;

  /// No description provided for @confirmMonitoringConsent.
  ///
  /// In en, this message translates to:
  /// **'I consent to monitoring of this device'**
  String get confirmMonitoringConsent;

  /// No description provided for @confirmMonitoringConsentDescription.
  ///
  /// In en, this message translates to:
  /// **'This includes all data collection activities listed above'**
  String get confirmMonitoringConsentDescription;

  /// No description provided for @confirmDataCollection.
  ///
  /// In en, this message translates to:
  /// **'I understand how my data will be collected and used'**
  String get confirmDataCollection;

  /// No description provided for @confirmDataCollectionDescription.
  ///
  /// In en, this message translates to:
  /// **'Including storage, processing, and sharing with authorized parties'**
  String get confirmDataCollectionDescription;

  /// No description provided for @digitalSignature.
  ///
  /// In en, this message translates to:
  /// **'Digital Signature'**
  String get digitalSignature;

  /// No description provided for @signatureInstructions.
  ///
  /// In en, this message translates to:
  /// **'Please sign below to provide your legal consent:'**
  String get signatureInstructions;

  /// No description provided for @clearSignature.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearSignature;

  /// No description provided for @signatureDate.
  ///
  /// In en, this message translates to:
  /// **'Date: {date}'**
  String signatureDate(String date);

  /// No description provided for @giveConsent.
  ///
  /// In en, this message translates to:
  /// **'Give Consent'**
  String get giveConsent;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// No description provided for @allConsentItemsRequired.
  ///
  /// In en, this message translates to:
  /// **'Please check all consent items before proceeding'**
  String get allConsentItemsRequired;

  /// No description provided for @signatureRequired.
  ///
  /// In en, this message translates to:
  /// **'Please provide your digital signature'**
  String get signatureRequired;

  /// No description provided for @signatureExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to export signature'**
  String get signatureExportFailed;

  /// No description provided for @viewTermsOfService.
  ///
  /// In en, this message translates to:
  /// **'View Terms of Service'**
  String get viewTermsOfService;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfServiceContent.
  ///
  /// In en, this message translates to:
  /// **'These terms govern your use of the XP SafeConnect monitoring application. By using this application, you agree to be monitored according to the capabilities described in this consent form. The monitoring is conducted for legitimate purposes such as parental control, family safety, or authorized workplace monitoring. You acknowledge that the data collected will be shared with authorized monitoring devices and may be used for safety, security, and compliance purposes.'**
  String get termsOfServiceContent;

  /// No description provided for @privacyPolicyContent.
  ///
  /// In en, this message translates to:
  /// **'Your privacy is important to us. This application collects location data, communication logs, application usage, and other device information for monitoring purposes. All data is encrypted during transmission and storage. Access to your data is limited to authorized monitoring administrators. You have the right to request access to your data, correction of inaccurate data, or deletion of your data subject to legal and safety requirements.'**
  String get privacyPolicyContent;

  /// No description provided for @processingConsent.
  ///
  /// In en, this message translates to:
  /// **'Processing Consent'**
  String get processingConsent;

  /// No description provided for @pleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait while we process your consent...'**
  String get pleaseWait;

  /// No description provided for @essentialPermissions.
  ///
  /// In en, this message translates to:
  /// **'Essential Permissions'**
  String get essentialPermissions;

  /// No description provided for @monitoringPermissions.
  ///
  /// In en, this message translates to:
  /// **'Monitoring Permissions'**
  String get monitoringPermissions;

  /// No description provided for @advancedPermissions.
  ///
  /// In en, this message translates to:
  /// **'Advanced Permissions'**
  String get advancedPermissions;

  /// No description provided for @optionalPermissions.
  ///
  /// In en, this message translates to:
  /// **'Optional Permissions'**
  String get optionalPermissions;

  /// No description provided for @checkingPermissions.
  ///
  /// In en, this message translates to:
  /// **'Checking Permissions'**
  String get checkingPermissions;

  /// No description provided for @noPermissionsToRequest.
  ///
  /// In en, this message translates to:
  /// **'No permissions to request'**
  String get noPermissionsToRequest;

  /// No description provided for @permissionStep.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String permissionStep(String current, String total);

  /// No description provided for @whyThisPermission.
  ///
  /// In en, this message translates to:
  /// **'Why this permission?'**
  String get whyThisPermission;

  /// No description provided for @requiredPermissionWarning.
  ///
  /// In en, this message translates to:
  /// **'This permission is required for the app to function properly'**
  String get requiredPermissionWarning;

  /// No description provided for @troubleshootingSteps.
  ///
  /// In en, this message translates to:
  /// **'Troubleshooting Steps'**
  String get troubleshootingSteps;

  /// No description provided for @needHelp.
  ///
  /// In en, this message translates to:
  /// **'Need Help?'**
  String get needHelp;

  /// No description provided for @hideTroubleshooting.
  ///
  /// In en, this message translates to:
  /// **'Hide Help'**
  String get hideTroubleshooting;

  /// No description provided for @skipOptional.
  ///
  /// In en, this message translates to:
  /// **'Skip (Optional)'**
  String get skipOptional;

  /// No description provided for @accessibilityPermission.
  ///
  /// In en, this message translates to:
  /// **'Accessibility Service'**
  String get accessibilityPermission;

  /// No description provided for @accessibilityPermissionDescription.
  ///
  /// In en, this message translates to:
  /// **'Allows monitoring of app usage and messaging'**
  String get accessibilityPermissionDescription;

  /// No description provided for @accessibilityPermissionDetailed.
  ///
  /// In en, this message translates to:
  /// **'The accessibility service is required to monitor app usage, detect messaging activity, and provide comprehensive device monitoring. This is essential for the monitoring functionality to work properly.'**
  String get accessibilityPermissionDetailed;

  /// No description provided for @usageStatsPermission.
  ///
  /// In en, this message translates to:
  /// **'Usage Statistics'**
  String get usageStatsPermission;

  /// No description provided for @usageStatsPermissionDescription.
  ///
  /// In en, this message translates to:
  /// **'Tracks which apps are used and for how long'**
  String get usageStatsPermissionDescription;

  /// No description provided for @usageStatsPermissionDetailed.
  ///
  /// In en, this message translates to:
  /// **'Usage statistics permission allows the app to track which applications are opened, how long they are used, and when they are closed. This data is essential for comprehensive device monitoring.'**
  String get usageStatsPermissionDetailed;

  /// No description provided for @deviceAdminPermission.
  ///
  /// In en, this message translates to:
  /// **'Device Administrator'**
  String get deviceAdminPermission;

  /// No description provided for @deviceAdminPermissionDescription.
  ///
  /// In en, this message translates to:
  /// **'Allows remote device control and anti-tamper protection'**
  String get deviceAdminPermissionDescription;

  /// No description provided for @deviceAdminPermissionDetailed.
  ///
  /// In en, this message translates to:
  /// **'Device administrator privileges enable remote locking/unlocking, prevent unauthorized uninstallation, and provide enhanced security features. This is optional but recommended for full functionality.'**
  String get deviceAdminPermissionDetailed;

  /// No description provided for @batteryOptimizationPermission.
  ///
  /// In en, this message translates to:
  /// **'Battery Optimization'**
  String get batteryOptimizationPermission;

  /// No description provided for @batteryOptimizationPermissionDescription.
  ///
  /// In en, this message translates to:
  /// **'Prevents the app from being killed by power management'**
  String get batteryOptimizationPermissionDescription;

  /// No description provided for @batteryOptimizationPermissionDetailed.
  ///
  /// In en, this message translates to:
  /// **'Disabling battery optimization ensures the app continues running in the background for continuous monitoring. This prevents Android\'s power management from stopping the monitoring service.'**
  String get batteryOptimizationPermissionDetailed;

  /// No description provided for @locationPermissionDetailed.
  ///
  /// In en, this message translates to:
  /// **'Location access is required for real-time GPS tracking. The app needs \'Allow all the time\' permission to track location even when the app is not actively being used.'**
  String get locationPermissionDetailed;

  /// No description provided for @phonePermissionDetailed.
  ///
  /// In en, this message translates to:
  /// **'Phone permission allows monitoring of incoming and outgoing calls, including call duration, contact information, and call state. This is essential for call monitoring features.'**
  String get phonePermissionDetailed;

  /// No description provided for @smsPermissionDetailed.
  ///
  /// In en, this message translates to:
  /// **'SMS permission enables monitoring of text messages, including reading incoming messages and tracking messaging activity. This is required for comprehensive communication monitoring.'**
  String get smsPermissionDetailed;

  /// No description provided for @cameraPermissionDetailed.
  ///
  /// In en, this message translates to:
  /// **'Camera access allows remote photo capture when requested by the monitoring device. This enables safety features like emergency photo capture.'**
  String get cameraPermissionDetailed;

  /// No description provided for @microphonePermissionDetailed.
  ///
  /// In en, this message translates to:
  /// **'Microphone access enables remote audio recording capabilities when requested by the monitoring device. This supports emergency monitoring and safety features.'**
  String get microphonePermissionDetailed;

  /// No description provided for @notificationPermissionDetailed.
  ///
  /// In en, this message translates to:
  /// **'Notification permission allows the app to show important alerts, status updates, and emergency notifications. This ensures you stay informed about the monitoring status.'**
  String get notificationPermissionDetailed;

  /// No description provided for @permissionSummary.
  ///
  /// In en, this message translates to:
  /// **'Permission Summary'**
  String get permissionSummary;

  /// No description provided for @permissionsConfigured.
  ///
  /// In en, this message translates to:
  /// **'Permissions Configured!'**
  String get permissionsConfigured;

  /// No description provided for @permissionsPartiallyConfigured.
  ///
  /// In en, this message translates to:
  /// **'Permissions Partially Configured'**
  String get permissionsPartiallyConfigured;

  /// No description provided for @permissionsGrantedSummary.
  ///
  /// In en, this message translates to:
  /// **'{granted} of {total} permissions granted'**
  String permissionsGrantedSummary(String granted, String total);

  /// No description provided for @permissionStatusDetails.
  ///
  /// In en, this message translates to:
  /// **'Permission Status Details'**
  String get permissionStatusDetails;

  /// No description provided for @granted.
  ///
  /// In en, this message translates to:
  /// **'Granted'**
  String get granted;

  /// No description provided for @notGranted.
  ///
  /// In en, this message translates to:
  /// **'Not Granted'**
  String get notGranted;

  /// No description provided for @incompletePermissionsWarning.
  ///
  /// In en, this message translates to:
  /// **'Some permissions are missing'**
  String get incompletePermissionsWarning;

  /// No description provided for @incompletePermissionsDescription.
  ///
  /// In en, this message translates to:
  /// **'The app may not function fully without all required permissions. You can continue with limited functionality or return to grant the missing permissions.'**
  String get incompletePermissionsDescription;

  /// No description provided for @reviewPermissions.
  ///
  /// In en, this message translates to:
  /// **'Review Permissions'**
  String get reviewPermissions;

  /// No description provided for @continueAnyway.
  ///
  /// In en, this message translates to:
  /// **'Continue Anyway'**
  String get continueAnyway;

  /// No description provided for @notificationPermission.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationPermission;

  /// No description provided for @notificationPermissionDescription.
  ///
  /// In en, this message translates to:
  /// **'Allows the app to display notifications'**
  String get notificationPermissionDescription;

  /// No description provided for @mediaPermissions.
  ///
  /// In en, this message translates to:
  /// **'Media Permissions'**
  String get mediaPermissions;

  /// No description provided for @systemPermissions.
  ///
  /// In en, this message translates to:
  /// **'System Permissions'**
  String get systemPermissions;

  /// No description provided for @whyDoWeNeedThis.
  ///
  /// In en, this message translates to:
  /// **'Why do we need this?'**
  String get whyDoWeNeedThis;

  /// No description provided for @permissionExplanation.
  ///
  /// In en, this message translates to:
  /// **'{explanation}'**
  String permissionExplanation(String explanation);

  /// No description provided for @locationAlwaysPermission.
  ///
  /// In en, this message translates to:
  /// **'Background Location'**
  String get locationAlwaysPermission;

  /// No description provided for @locationAlwaysPermissionDescription.
  ///
  /// In en, this message translates to:
  /// **'Allows location tracking even when the app is not open'**
  String get locationAlwaysPermissionDescription;

  /// No description provided for @locationAlwaysPermissionExplanation.
  ///
  /// In en, this message translates to:
  /// **'Background location access is required for continuous location tracking. This ensures the monitoring device can always know your location for safety purposes.'**
  String get locationAlwaysPermissionExplanation;

  /// No description provided for @locationPermissionExplanation.
  ///
  /// In en, this message translates to:
  /// **'Location access is required for real-time GPS tracking. The app needs location permission to track your position for safety and monitoring purposes.'**
  String get locationPermissionExplanation;

  /// No description provided for @smsPermissionExplanation.
  ///
  /// In en, this message translates to:
  /// **'SMS permission enables monitoring of text messages, including reading incoming messages and tracking messaging activity. This is required for comprehensive communication monitoring.'**
  String get smsPermissionExplanation;

  /// No description provided for @phonePermissionExplanation.
  ///
  /// In en, this message translates to:
  /// **'Phone permission allows monitoring of incoming and outgoing calls, including call duration, contact information, and call state. This is essential for call monitoring features.'**
  String get phonePermissionExplanation;

  /// No description provided for @usageStatsPermissionExplanation.
  ///
  /// In en, this message translates to:
  /// **'Usage statistics permission allows the app to track which applications are opened, how long they are used, and when they are closed. This data is essential for comprehensive device monitoring.'**
  String get usageStatsPermissionExplanation;

  /// No description provided for @accessibilityServicePermissionExplanation.
  ///
  /// In en, this message translates to:
  /// **'The accessibility service is required to monitor app usage, detect messaging activity, and provide comprehensive device monitoring. This is essential for the monitoring functionality to work properly.'**
  String get accessibilityServicePermissionExplanation;

  /// No description provided for @cameraPermissionExplanation.
  ///
  /// In en, this message translates to:
  /// **'Camera access allows remote photo capture when requested by the monitoring device. This enables safety features like emergency photo capture.'**
  String get cameraPermissionExplanation;

  /// No description provided for @microphonePermissionExplanation.
  ///
  /// In en, this message translates to:
  /// **'Microphone access enables remote audio recording capabilities when requested by the monitoring device. This supports emergency monitoring and safety features.'**
  String get microphonePermissionExplanation;

  /// No description provided for @storagePermissionExplanation.
  ///
  /// In en, this message translates to:
  /// **'Storage permission allows access to files and media on your device. This is needed to save monitoring data and access device content when required.'**
  String get storagePermissionExplanation;

  /// No description provided for @deviceAdminPermissionExplanation.
  ///
  /// In en, this message translates to:
  /// **'Device administrator privileges enable remote locking/unlocking, prevent unauthorized uninstallation, and provide enhanced security features. This is optional but recommended for full functionality.'**
  String get deviceAdminPermissionExplanation;

  /// No description provided for @batteryOptimizationPermissionExplanation.
  ///
  /// In en, this message translates to:
  /// **'Disabling battery optimization ensures the app continues running in the background for continuous monitoring. This prevents Android\'s power management from stopping the monitoring service.'**
  String get batteryOptimizationPermissionExplanation;

  /// No description provided for @notificationPermissionExplanation.
  ///
  /// In en, this message translates to:
  /// **'Notification permission allows the app to show important alerts, status updates, and emergency notifications. This ensures you stay informed about the monitoring status.'**
  String get notificationPermissionExplanation;

  /// No description provided for @optionalPermission.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optionalPermission;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @completeSetup.
  ///
  /// In en, this message translates to:
  /// **'Complete Setup'**
  String get completeSetup;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission Denied'**
  String get permissionDenied;

  /// No description provided for @permissionPermanentlyDeniedMessage.
  ///
  /// In en, this message translates to:
  /// **'This permission has been permanently denied. You can grant it manually in the app settings.'**
  String get permissionPermanentlyDeniedMessage;

  /// No description provided for @incompleteSetup.
  ///
  /// In en, this message translates to:
  /// **'Incomplete Setup'**
  String get incompleteSetup;

  /// No description provided for @requiredPermissionsMissing.
  ///
  /// In en, this message translates to:
  /// **'Some required permissions are still missing:'**
  String get requiredPermissionsMissing;

  /// No description provided for @p2pConnectionStatus.
  ///
  /// In en, this message translates to:
  /// **'P2P Connection Status'**
  String get p2pConnectionStatus;

  /// No description provided for @addConnection.
  ///
  /// In en, this message translates to:
  /// **'Add Connection'**
  String get addConnection;

  /// No description provided for @activeConnections.
  ///
  /// In en, this message translates to:
  /// **'Active Connections'**
  String get activeConnections;

  /// No description provided for @noActiveConnections.
  ///
  /// In en, this message translates to:
  /// **'No active connections'**
  String get noActiveConnections;

  /// No description provided for @p2pUninitialized.
  ///
  /// In en, this message translates to:
  /// **'Not initialized'**
  String get p2pUninitialized;

  /// No description provided for @p2pInitializing.
  ///
  /// In en, this message translates to:
  /// **'Initializing...'**
  String get p2pInitializing;

  /// No description provided for @p2pReady.
  ///
  /// In en, this message translates to:
  /// **'Ready for connections'**
  String get p2pReady;

  /// No description provided for @p2pConnectedDevices.
  ///
  /// In en, this message translates to:
  /// **'{count} devices connected'**
  String p2pConnectedDevices(String count);

  /// No description provided for @p2pConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get p2pConnecting;

  /// No description provided for @p2pConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get p2pConnected;

  /// No description provided for @p2pDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get p2pDisconnected;

  /// No description provided for @p2pError.
  ///
  /// In en, this message translates to:
  /// **'Connection error'**
  String get p2pError;

  /// No description provided for @connectToDevice.
  ///
  /// In en, this message translates to:
  /// **'Connect to Device'**
  String get connectToDevice;

  /// No description provided for @deviceId.
  ///
  /// In en, this message translates to:
  /// **'Device ID'**
  String get deviceId;

  /// No description provided for @enterDeviceId.
  ///
  /// In en, this message translates to:
  /// **'Enter device ID'**
  String get enterDeviceId;

  /// No description provided for @p2pConnectionInfo.
  ///
  /// In en, this message translates to:
  /// **'Enter the device ID of the monitoring device you want to connect to directly.'**
  String get p2pConnectionInfo;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @connectingToDevice.
  ///
  /// In en, this message translates to:
  /// **'Connecting to device...'**
  String get connectingToDevice;

  /// No description provided for @connectionSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Connection successful'**
  String get connectionSuccessful;

  /// No description provided for @connectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed'**
  String get connectionFailed;

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'Connection error occurred'**
  String get connectionError;

  /// No description provided for @connectedAt.
  ///
  /// In en, this message translates to:
  /// **'Connected at'**
  String get connectedAt;

  /// No description provided for @sendCommand.
  ///
  /// In en, this message translates to:
  /// **'Send Command'**
  String get sendCommand;

  /// No description provided for @sendFile.
  ///
  /// In en, this message translates to:
  /// **'Send File'**
  String get sendFile;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @lockDevice.
  ///
  /// In en, this message translates to:
  /// **'Lock Device'**
  String get lockDevice;

  /// No description provided for @unlockDevice.
  ///
  /// In en, this message translates to:
  /// **'Unlock Device'**
  String get unlockDevice;

  /// No description provided for @restartDevice.
  ///
  /// In en, this message translates to:
  /// **'Restart Device'**
  String get restartDevice;

  /// No description provided for @capturePhoto.
  ///
  /// In en, this message translates to:
  /// **'Capture Photo'**
  String get capturePhoto;

  /// No description provided for @commandSent.
  ///
  /// In en, this message translates to:
  /// **'Command sent successfully'**
  String get commandSent;

  /// No description provided for @commandFailed.
  ///
  /// In en, this message translates to:
  /// **'Command failed'**
  String get commandFailed;

  /// No description provided for @commandError.
  ///
  /// In en, this message translates to:
  /// **'Error sending command'**
  String get commandError;

  /// No description provided for @confirmDisconnection.
  ///
  /// In en, this message translates to:
  /// **'Confirm Disconnection'**
  String get confirmDisconnection;

  /// No description provided for @disconnectDeviceConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to disconnect from {deviceName}?'**
  String disconnectDeviceConfirmation(String deviceName);

  /// No description provided for @deviceDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Device disconnected'**
  String get deviceDisconnected;

  /// No description provided for @disconnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Disconnection failed'**
  String get disconnectionFailed;

  /// No description provided for @invalidPairingCodeFormat.
  ///
  /// In en, this message translates to:
  /// **'The pairing code must contain 6 digits'**
  String get invalidPairingCodeFormat;

  /// No description provided for @pairingFailed.
  ///
  /// In en, this message translates to:
  /// **'Pairing failed'**
  String get pairingFailed;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error'**
  String get networkError;

  /// No description provided for @logoutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Logout Confirmation'**
  String get logoutConfirmation;

  /// No description provided for @logoutConfirmationMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout? The application will be closed and will need to be paired again.'**
  String get logoutConfirmationMessage;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
