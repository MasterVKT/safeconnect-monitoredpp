// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'XP SafeConnect';

  @override
  String get welcomeToSafeConnect => 'Bienvenue sur XP SafeConnect';

  @override
  String get pairingScreenDescription => 'Veuillez saisir le code de jumelage fourni par l\'appareil de surveillance pour démarrer le processus de configuration.';

  @override
  String get pairingCode => 'Code de jumelage';

  @override
  String get enterPairingCode => 'Entrez le code à 6 chiffres';

  @override
  String get pairingCodeRequired => 'Veuillez entrer le code de jumelage';

  @override
  String get continueText => 'Continuer';

  @override
  String get cancel => 'Annuler';

  @override
  String get exitSetup => 'Quitter la configuration';

  @override
  String get exitSetupConfirmation => 'Êtes-vous sûr de vouloir quitter la configuration ? Cela fermera l\'application.';

  @override
  String get exit => 'Quitter';

  @override
  String get requiredPermissions => 'Permissions requises';

  @override
  String permissionTitle(String title) {
    return '$title';
  }

  @override
  String permissionDescription(String description) {
    return '$description';
  }

  @override
  String get locationPermission => 'Localisation';

  @override
  String get locationPermissionDescription => 'Permet de suivre la position de votre appareil en temps réel. Cela est nécessaire pour que l\'appareil de surveillance puisse voir où vous vous trouvez.';

  @override
  String get smsPermission => 'Messages SMS';

  @override
  String get smsPermissionDescription => 'Permet d\'accéder aux messages SMS envoyés et reçus sur cet appareil.';

  @override
  String get phonePermission => 'Appels téléphoniques';

  @override
  String get phonePermissionDescription => 'Permet de surveiller les appels entrants et sortants sur cet appareil.';

  @override
  String get storagePermission => 'Stockage';

  @override
  String get storagePermissionDescription => 'Permet d\'accéder aux images et autres fichiers stockés sur cet appareil.';

  @override
  String get cameraPermission => 'Caméra';

  @override
  String get cameraPermissionDescription => 'Permet la capture de photos à distance en utilisant la caméra de cet appareil lorsque demandé.';

  @override
  String get microphonePermission => 'Microphone';

  @override
  String get microphonePermissionDescription => 'Permet l\'enregistrement audio à distance en utilisant le microphone de cet appareil lorsque demandé.';

  @override
  String get requiredPermission => 'Obligatoire';

  @override
  String get permissionGranted => 'Permission accordée';

  @override
  String get permissionRequired => 'Permission requise';

  @override
  String get grantPermission => 'Accorder la permission';

  @override
  String get back => 'Retour';

  @override
  String get continueToSetup => 'Continuer vers la configuration';

  @override
  String get finalSetup => 'Configuration finale';

  @override
  String get permissionsGranted => 'Permissions accordées !';

  @override
  String get displayMode => 'Mode d\'affichage';

  @override
  String get displayModeNormal => 'Normal';

  @override
  String get displayModeNormalDesc => 'L\'icône et le nom de l\'application seront visibles dans le tiroir d\'applications.';

  @override
  String get displayModeDiscrete => 'Discret';

  @override
  String get displayModeDiscreteDesc => 'L\'application utilisera un nom et une icône génériques pour éviter la détection.';

  @override
  String get displayModeHidden => 'Caché';

  @override
  String get displayModeHiddenDesc => 'L\'application n\'apparaîtra pas dans le tiroir d\'applications (accès via un code de numérotation).';

  @override
  String get autoStart => 'Démarrage automatique';

  @override
  String get autoStartDescription => 'Démarrer automatiquement l\'application au démarrage de l\'appareil.';

  @override
  String get notificationMode => 'Mode de notification';

  @override
  String get notificationModeVisible => 'Visible';

  @override
  String get notificationModeVisibleDesc => 'Notifications normales avec le nom et l\'icône de l\'application.';

  @override
  String get notificationModeMinimized => 'Minimisées';

  @override
  String get notificationModeMinimizedDesc => 'Notifications compactes avec un minimum d\'informations.';

  @override
  String get notificationModeHidden => 'Cachées';

  @override
  String get notificationModeHiddenDesc => 'Pas de notifications visibles (service d\'arrière-plan uniquement).';

  @override
  String get importantInfo => 'Information importante';

  @override
  String get backgroundServiceInfo => 'Cette application fonctionnera en continu en arrière-plan pour fournir des capacités de surveillance. Cela peut affecter la durée de vie de la batterie. Le service d\'arrière-plan redémarrera automatiquement s\'il est terminé.';

  @override
  String get finishSetup => 'Terminer la configuration';

  @override
  String get errorOccurred => 'Une erreur s\'est produite';

  @override
  String get close => 'Fermer';

  @override
  String get settings => 'Paramètres';

  @override
  String get connected => 'Connecté';

  @override
  String get disconnected => 'Déconnecté';

  @override
  String connectedToDevice(String device) {
    return 'Connecté à $device';
  }

  @override
  String get notConnectedToAnyDevice => 'Non connecté à un appareil de surveillance';

  @override
  String get monitoringStatus => 'État de la surveillance';

  @override
  String get locationTracking => 'Suivi de localisation';

  @override
  String get messageMonitoring => 'Surveillance des messages';

  @override
  String get callsMonitoring => 'Surveillance des appels';

  @override
  String get appsMonitoring => 'Surveillance des applications';

  @override
  String get photosAccess => 'Accès aux photos';

  @override
  String get quickActions => 'Actions rapides';

  @override
  String get viewSharedData => 'Voir les données partagées';

  @override
  String get contactMonitor => 'Contacter le surveillant';

  @override
  String get featureComingSoon => 'Cette fonctionnalité arrive bientôt';

  @override
  String get holdForEmergency => 'Maintenir pour urgence';

  @override
  String featureActiveAndSharing(String feature) {
    return '$feature est actif et partage des données';
  }

  @override
  String featureNotActive(String feature) {
    return '$feature n\'est pas actif';
  }

  @override
  String get sharedData => 'Données partagées';

  @override
  String get aboutSharedData => 'À propos des données partagées';

  @override
  String get sharedDataExplanation => 'Cet écran vous montre quelles données sont partagées avec l\'appareil de surveillance. Vous ne pouvez pas désactiver ces fonctionnalités car elles font partie de l\'accord de surveillance.';

  @override
  String get location => 'Localisation';

  @override
  String get messages => 'Messages';

  @override
  String get calls => 'Appels';

  @override
  String get apps => 'Applications';

  @override
  String get photos => 'Photos';

  @override
  String get active => 'Actif';

  @override
  String get inactive => 'Inactif';

  @override
  String lastSyncTime(String time) {
    return 'Dernière synchronisation : $time';
  }

  @override
  String get viewPrivacyPolicy => 'Voir la politique de confidentialité';

  @override
  String get locationSharingDescription => 'Votre position actuelle est partagée avec l\'appareil de surveillance en temps réel. Cela inclut vos coordonnées GPS, la précision et la vitesse de déplacement.';

  @override
  String get messagesSharingDescription => 'Vos messages SMS et certains contenus des applications de messagerie sont partagés avec l\'appareil de surveillance.';

  @override
  String get callsSharingDescription => 'Les informations sur vos appels entrants et sortants sont partagées, y compris le numéro de téléphone, le nom du contact et la durée de l\'appel.';

  @override
  String get appsSharingDescription => 'Des informations sur les applications que vous utilisez et leur durée d\'utilisation sont partagées avec l\'appareil de surveillance.';

  @override
  String get photosSharingDescription => 'L\'accès aux photos n\'est actuellement pas activé sur cet appareil.';

  @override
  String get emergencyMode => 'Mode d\'urgence';

  @override
  String get emergencyModeActive => 'MODE D\'URGENCE ACTIF';

  @override
  String get emergencyModeDescription => 'En cas de situation d\'urgence, appuyez sur le bouton ci-dessous pour alerter l\'appareil de surveillance. Il sera immédiatement notifié et pourra prendre les mesures appropriées.';

  @override
  String get tapToActivate => 'Appuyez pour activer';

  @override
  String get emergencyModeWarning => 'Utilisez ceci uniquement en cas d\'urgence réelle. Les fausses alarmes peuvent entraîner la restriction de cette fonctionnalité.';

  @override
  String activatingEmergencyIn(String seconds) {
    return 'Activation du mode d\'urgence dans ${seconds}s';
  }

  @override
  String get cancelEmergency => 'Annuler';

  @override
  String get tapToCancelEmergency => 'Appuyez pour annuler l\'activation d\'urgence';

  @override
  String get emergencyModeActivated => 'Mode d\'urgence activé';

  @override
  String get monitoringDeviceNotified => 'L\'appareil de surveillance a été notifié de votre situation d\'urgence.';

  @override
  String get emergencyActions => 'Actions d\'urgence';

  @override
  String get takePhoto => 'Prendre photo';

  @override
  String get recordAudio => 'Enregistrer audio';

  @override
  String get sendMessage => 'Envoyer message';

  @override
  String get deactivateEmergencyMode => 'Désactiver le mode d\'urgence';

  @override
  String get justNow => 'à l\'instant';

  @override
  String minutesAgo(String minutes) {
    return 'il y a $minutes minutes';
  }

  @override
  String hoursAgo(String hours) {
    return 'il y a $hours heures';
  }

  @override
  String daysAgo(String days) {
    return 'il y a $days jours';
  }

  @override
  String get remoteUnlockRequested => 'Déverrouillage à distance demandé';

  @override
  String get deviceUnlocked => 'Appareil déverrouillé';

  @override
  String get unlockPermissionRequired => 'Cette application nécessite la permission de déverrouiller votre appareil';

  @override
  String get scanQRCode => 'Scanner le code QR';

  @override
  String get qrScanInstructions => 'Positionnez le code QR dans le cadre pour le scanner';

  @override
  String get enterCodeManually => 'Saisir le code manuellement';

  @override
  String get invalidQRCode => 'Format de code QR invalide';

  @override
  String get error => 'Erreur';

  @override
  String get ok => 'OK';

  @override
  String get confirm => 'Confirmer';
}
