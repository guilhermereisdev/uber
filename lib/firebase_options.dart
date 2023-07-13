// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
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
      return web;
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB4UtwHUVcopUvIJAtW9BpAsvFISw9XUH8',
    appId: '1:625128337187:web:497ccf0763031d4721e696',
    messagingSenderId: '625128337187',
    projectId: 'uber-gui',
    authDomain: 'uber-gui.firebaseapp.com',
    storageBucket: 'uber-gui.appspot.com',
    measurementId: 'G-5JPR09D4VL',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAUnB4mX5BSf4n6z1h1hfDzA3yDAHCT8wk',
    appId: '1:625128337187:android:b3fcfa4eedac3c7621e696',
    messagingSenderId: '625128337187',
    projectId: 'uber-gui',
    storageBucket: 'uber-gui.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA_BdAXm1tO9nMYflNG7g2QNSfeiUJYfs0',
    appId: '1:625128337187:ios:6871c62e0b0160ce21e696',
    messagingSenderId: '625128337187',
    projectId: 'uber-gui',
    storageBucket: 'uber-gui.appspot.com',
    iosClientId:
        '625128337187-jd28arom8s2bain629rp9sk3umhfcob6.apps.googleusercontent.com',
    iosBundleId: 'com.guilhermereisapps.uber',
  );
}
