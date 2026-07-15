import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions belum sepenuhnya dikonfigurasi untuk platform Web.',
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

  // DIKOREKSI: Membaca kredensial sensitif dari .env agar aman dari pembajakan repositori Git
  static FirebaseOptions get android => FirebaseOptions(
    apiKey: dotenv.get('FIREBASE_API_KEY', fallback: 'KEY_NOT_FOUND'),
    appId: dotenv.get('FIREBASE_APP_ID_ANDROID', fallback: 'APP_ID_NOT_FOUND'),
    messagingSenderId: dotenv.get('FIREBASE_SENDER_ID', fallback: ''),
    projectId: dotenv.get('FIREBASE_PROJECT_ID', fallback: ''),
    storageBucket: '${dotenv.get('FIREBASE_PROJECT_ID', fallback: '')}.firebasestorage.app',
    authDomain: '${dotenv.get('FIREBASE_PROJECT_ID', fallback: '')}.firebaseapp.com',
  );
}
