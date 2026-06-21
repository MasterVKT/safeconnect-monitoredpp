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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr')
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
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'fr': return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
