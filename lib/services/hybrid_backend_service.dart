import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class HybridBackendService {
  HybridBackendService._();

  static StreamSubscription<User?>? _authSubscription;
  static StreamSubscription<String>? _tokenSubscription;
  static bool _initialized = false;

  static const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const _supabasePublishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static bool get isConfigured => _supabaseUrl.isNotEmpty && _supabasePublishableKey.isNotEmpty;
  static SupabaseClient get client => Supabase.instance.client;

  static Future<String> uploadStorageFile({
    required String bucket,
    required String path,
    required File file,
    required String contentType,
    bool public = false,
  }) async {
    final storage = client.storage.from(bucket);
    await storage.upload(
      path,
      file,
      fileOptions: FileOptions(contentType: contentType, upsert: true),
    );
    return public ? storage.getPublicUrl(path) : path;
  }

  static Future<String> createPrivateFileUrl(
    String path, {
    String bucket = 'user-files',
    int expiresInSeconds = 3600,
  }) {
    return client.storage.from(bucket).createSignedUrl(path, expiresInSeconds);
  }

  static String publicFileUrl(String bucket, String path) {
    return client.storage.from(bucket).getPublicUrl(path);
  }

  /// Crash reporting is intentionally local-only: Firebase Crashlytics is
  /// excluded so its missing Android component cannot block Firebase startup.
  static void recordError(Object error, StackTrace stack, {String? reason}) {
    debugPrint('[$reason] $error\n$stack');
  }

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (!isConfigured) {
      debugPrint('Supabase belum dikonfigurasi; Firebase Auth tetap aktif.');
      return;
    }

    await Supabase.initialize(
      url: _supabaseUrl,
      publishableKey: _supabasePublishableKey,
      accessToken: () async => FirebaseAuth.instance.currentUser?.getIdToken(),
    );

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) unawaited(_registerCurrentDevice());
    });
    _tokenSubscription = FirebaseMessaging.instance.onTokenRefresh.listen((_) {
      unawaited(_registerCurrentDevice());
    });
    if (FirebaseAuth.instance.currentUser != null) await _registerCurrentDevice();
  }

  static Future<void> _registerCurrentDevice() async {
    if (!isConfigured || FirebaseAuth.instance.currentUser == null) return;
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      final token = await messaging.getToken();
      if (token == null || token.isEmpty) return;
      await Supabase.instance.client.functions.invoke(
        'register-device',
        body: {'token': token, 'platform': Platform.isIOS ? 'ios' : 'android'},
      );
    } catch (error, stack) {
      recordError(error, stack, reason: 'FCM device registration failed');
    }
  }

  /// Call before FirebaseAuth.signOut() so the Firebase ID token is still available.
  static Future<void> unregisterCurrentDevice() async {
    if (!isConfigured || FirebaseAuth.instance.currentUser == null) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      await Supabase.instance.client.functions.invoke('unregister-device', body: {'token': token});
    } catch (error, stack) {
      recordError(error, stack, reason: 'FCM device unregistration failed');
    }
  }

  static Future<void> dispose() async {
    await _authSubscription?.cancel();
    await _tokenSubscription?.cancel();
    _authSubscription = null;
    _tokenSubscription = null;
    _initialized = false;
  }
}
