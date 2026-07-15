import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] untuk inisialisasi Firebase di berbagai platform.
///
/// Berkas ini dikonfigurasi secara aman untuk mendukung skalabilitas multi-platform DesaPay.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      // Siapkan konfigurasi Web jika ke depannya rilis versi Web Dashboard
      return web;
    }
    
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions belum dikonfigurasi untuk platform macOS.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions belum dikonfigurasi untuk platform Windows.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions belum dikonfigurasi untuk platform Linux.',
        );
      default:
        throw UnsupportedError(
          'Platform saat ini tidak didukung oleh Firebase DesaPay.',
        );
    }
  }

  // ===================================================
  // 1. KONFIGURASI PLATFORM ANDROID (ACTIVE)
  // ===================================================
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB-guTai42pYgcvXeacyt_8fyUpkfxzluA',
    appId: '1:242778852239:android:746f364459e64879fe99fa',
    messagingSenderId: '242778852239',
    projectId: 'desapay-10614',
    storageBucket: 'desapay-10614.firebasestorage.app',
    authDomain: 'desapay-10614.firebaseapp.com',
  );

  // ===================================================
  // 2. SKAFOLDING PLATFORM IOS (SCAFFOLDED FOR FUTURE BUILD)
  // ===================================================
  // Ganti nilai di bawah ini jika nanti Anda mendaftarkan bundle ID iOS di Firebase Console
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB-guTai42pYgcvXeacyt_8fyUpkfxzluA',
    appId: '1:242778852239:ios:746f364459e64879fe99fa', // Placeholder ID
    messagingSenderId: '242778852239',
    projectId: 'desapay-10614',
    storageBucket: 'desapay-10614.firebasestorage.app',
    iosBundleId: 'com.desapay.app',
  );

  // ===================================================
  // 3. SKAFOLDING PLATFORM WEB (SCAFFOLDED FOR FUTURE BUILD)
  // ===================================================
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB-guTai42pYgcvXeacyt_8fyUpkfxzluA',
    appId: '1:242778852239:web:746f364459e64879fe99fa', // Placeholder ID
    messagingSenderId: '242778852239',
    projectId: 'desapay-10614',
    authDomain: 'desapay-10614.firebaseapp.com',
    storageBucket: 'desapay-10614.firebasestorage.app',
  );
}
