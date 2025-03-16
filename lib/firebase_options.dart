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
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for android - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
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
    apiKey: 'AIzaSyAY3N3Ekmj_drw3P2QlsyyWiW1OPkG0jxU',
    appId: '1:603917507536:web:a5cea742df6380029237d5',
    messagingSenderId: '603917507536',
    projectId: 'forrent-b4654',
    authDomain: 'forrent-b4654.firebaseapp.com',
    storageBucket: 'forrent-b4654.appspot.com',
    measurementId: 'G-8XP91P1R4E',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyD15KE6_i5oXIsNlyT1WdR0ZrK0tQdFUxg',
    appId: '1:603917507536:ios:547cc937591d332e9237d5',
    messagingSenderId: '603917507536',
    projectId: 'forrent-b4654',
    storageBucket: 'forrent-b4654.appspot.com',
    iosBundleId: 'com.example.schoolManagementDashboard',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAY3N3Ekmj_drw3P2QlsyyWiW1OPkG0jxU',
    appId: '1:603917507536:web:5737f233e62ca42a9237d5',
    messagingSenderId: '603917507536',
    projectId: 'forrent-b4654',
    authDomain: 'forrent-b4654.firebaseapp.com',
    storageBucket: 'forrent-b4654.appspot.com',
    measurementId: 'G-3QQ23KR0LB',
  );
}
