// =====================================================================
// FILE: lib/firebase_options.dart
// =====================================================================

import 'package:firebase_core/firebase_core.dart';

import 'package:flutter/foundation.dart'
    show
        defaultTargetPlatform,
        kIsWeb,
        TargetPlatform;

// =====================================================================
// DEFAULT FIREBASE OPTIONS
// =====================================================================
//
// DesaPay menggunakan Firebase untuk:
// - Firebase Authentication
// - Cloud Firestore
// - Firebase Storage
// - Cloud Functions
//
// Konfigurasi Android diambil dari --dart-define saat build.
//
// Contoh:
//
// --dart-define=FIREBASE_API_KEY=xxxxx
// --dart-define=FIREBASE_APP_ID_ANDROID=xxxxx
// --dart-define=FIREBASE_SENDER_ID=xxxxx
// --dart-define=FIREBASE_PROJECT_ID=xxxxx
// --dart-define=FIREBASE_STORAGE_BUCKET=xxxxx
//
// Jangan memasukkan service account / private key ke aplikasi.
// =====================================================================

class DefaultFirebaseOptions {
  // ===================================================================
  // CURRENT PLATFORM
  // ===================================================================

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

      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        throw UnsupportedError(
          'Platform ini tidak didukung oleh Firebase DesaPay.',
        );
    }
  }

  // ===================================================================
  // ANDROID
  // ===================================================================

  static const FirebaseOptions android =
      FirebaseOptions(
    apiKey: String.fromEnvironment(
      'FIREBASE_API_KEY',
    ),

    appId: String.fromEnvironment(
      'FIREBASE_APP_ID_ANDROID',
    ),

    messagingSenderId:
        String.fromEnvironment(
      'FIREBASE_SENDER_ID',
    ),

    projectId:
        String.fromEnvironment(
      'FIREBASE_PROJECT_ID',
    ),

    storageBucket:
        String.fromEnvironment(
      'FIREBASE_STORAGE_BUCKET',
    ),
  );
}
