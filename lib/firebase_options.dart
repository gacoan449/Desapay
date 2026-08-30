import 'package:firebase_core/firebase_core.dart';

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions belum dikonfigurasi untuk platform Web.',
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;

      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions belum dikonfigurasi untuk platform iOS.',
        );

      default:
        throw UnsupportedError(
          'Platform ini tidak didukung oleh Firebase DesaPay.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_API_KEY'),
    appId: String.fromEnvironment('FIREBASE_APP_ID_ANDROID'),
    messagingSenderId: String.fromEnvironment('FIREBASE_SENDER_ID'),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
    storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
    authDomain: String.fromEnvironment('FIREBASE_AUTH_DOMAIN'),
  );
}
