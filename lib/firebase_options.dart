// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBbMpBxPq8eWuLPmZiocejPOCO5yoyL2k0',
    appId: '1:890256441645:android:d7b9de3875862cf9a393a4',
    messagingSenderId: '890256441645',
    projectId: 'xp-safeconnect',
    storageBucket: 'xp-safeconnect.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDbRVFRtB5XjUHURzJecaUT6tHtHeyektM',
    appId: '1:890256441645:ios:76b6e704b29665f2a393a4',
    messagingSenderId: '890256441645',
    projectId: 'xp-safeconnect',
    storageBucket: 'xp-safeconnect.firebasestorage.app',
    androidClientId: '890256441645-ckjbkhbetj3e4l0bc0egcfpjash6v5jv.apps.googleusercontent.com',
    iosClientId: '890256441645-pv8us2vcjr153cvuc1koub99ft73bo91.apps.googleusercontent.com',
    iosBundleId: 'com.xpsafeconnect.monitoredApp',
  );
}
