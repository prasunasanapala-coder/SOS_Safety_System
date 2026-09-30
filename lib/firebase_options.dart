import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

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
        return macos;
      case TargetPlatform.windows:
        return windows;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDUMMYWEBKEY1234567890abcdefg',
    appId: '1:1234567890:web:demo-sos-safety',
    messagingSenderId: '1234567890',
    projectId: 'demo-sos-safety',
    authDomain: 'demo-sos-safety.firebaseapp.com',
    storageBucket: 'demo-sos-safety.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDUMMYANDROIDKEY1234567890',
    appId: '1:1234567890:android:demo-sos-safety',
    messagingSenderId: '1234567890',
    projectId: 'demo-sos-safety',
    storageBucket: 'demo-sos-safety.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDUMMYIOSKEY1234567890abcdef',
    appId: '1:1234567890:ios:demo-sos-safety',
    messagingSenderId: '1234567890',
    projectId: 'demo-sos-safety',
    storageBucket: 'demo-sos-safety.firebasestorage.app',
    iosBundleId: 'com.example.sosSafety',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDUMMYMACOSKEY1234567890ab',
    appId: '1:1234567890:macos:demo-sos-safety',
    messagingSenderId: '1234567890',
    projectId: 'demo-sos-safety',
    storageBucket: 'demo-sos-safety.firebasestorage.app',
    iosBundleId: 'com.example.sosSafety',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDUMMYWINDOWSKEY1234567890',
    appId: '1:1234567890:windows:demo-sos-safety',
    messagingSenderId: '1234567890',
    projectId: 'demo-sos-safety',
    storageBucket: 'demo-sos-safety.firebasestorage.app',
  );
}
