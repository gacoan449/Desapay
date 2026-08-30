// =====================================================================
// FILE: lib/main.dart
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'config/warna.dart';
import 'firebase_options.dart';

import 'screens/splash/splash_screen.dart';
import 'screens/login/login_screen.dart';
import 'widgets/bottom_nav.dart';
import 'screens/admin/admin_dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // =========================================================
  // PORTRAIT ONLY
  // =========================================================

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // =========================================================
  // FIREBASE
  // =========================================================

  FirebaseApp? firebaseApp;
  String? firebaseError;

  try {
    firebaseApp = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    debugPrint(
      'DesaPay Firebase berhasil terhubung: ${firebaseApp.name}',
    );
  } catch (e, stackTrace) {
    firebaseError = e.toString();

    debugPrint(
      'Firebase initialization gagal: $e',
    );

    debugPrint(
      stackTrace.toString(),
    );
  }

  // =========================================================
  // APP
  // =========================================================

  runApp(
    DesaPayApp(
      firebaseReady: firebaseApp != null,
      firebaseError: firebaseError,
    ),
  );
}

class DesaPayApp extends StatelessWidget {
  final bool firebaseReady;
  final String? firebaseError;

  const DesaPayApp({
    super.key,
    required this.firebaseReady,
    this.firebaseError,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DesaPay',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: WarnaDesaPay.primary,
          primary: WarnaDesaPay.primary,
          onPrimary: Colors.white,
          secondary: WarnaDesaPay.secondary,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: WarnaDesaPay.lightBg,
        fontFamily: 'Inter',
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),

      home: !firebaseReady
          ? FirebaseErrorScreen(
              error: firebaseError ?? 'Unknown Firebase error',
            )
          : const DesaPayHome(),
    );
  }
}

// =====================================================================
// FIREBASE ERROR SCREEN
// =====================================================================

class FirebaseErrorScreen extends StatelessWidget {
  final String error;

  const FirebaseErrorScreen({
    super.key,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WarnaDesaPay.lightBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.cloud_off,
                  size: 72,
                  color: Colors.red,
                ),

                const SizedBox(height: 20),

                const Text(
                  'DesaPay gagal memulai',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'Firebase tidak berhasil diinisialisasi.',
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SelectableText(
                    error,
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// DESAPAY HOME
// =====================================================================

class DesaPayHome extends StatelessWidget {
  const DesaPayHome({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),

      builder: (context, snapshot) {
        // ===================================================
        // FIREBASE AUTH SEDANG CEK SESSION
        // ===================================================

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const SplashScreen();
        }

        // ===================================================
        // AUTH ERROR
        // ===================================================

        if (snapshot.hasError) {
          return AuthErrorScreen(
            error: snapshot.error.toString(),
          );
        }

        // ===================================================
        // BELUM LOGIN
        // ===================================================

        final user = snapshot.data;

        if (user == null) {
          return const LoginScreen();
        }

        // ===================================================
        // CEK ROLE FIRESTORE
        // ===================================================

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),

          builder: (context, userSnap) {
            // =================================================
            // FIRESTORE SEDANG MEMUAT
            // =================================================

            if (userSnap.connectionState ==
                ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(
                    color: WarnaDesaPay.primary,
                  ),
                ),
              );
            }

            // =================================================
            // FIRESTORE ERROR
            // =================================================

            if (userSnap.hasError) {
              return AuthErrorScreen(
                error: userSnap.error.toString(),
              );
            }

            // =================================================
            // USER ADA
            // =================================================

            if (userSnap.hasData &&
                userSnap.data!.exists) {
              final rawData = userSnap.data!.data();

              if (rawData is Map<String, dynamic>) {
                if (rawData['role'] == 'admin') {
                  return const AdminDashboardScreen();
                }
              }
            }

            // =================================================
            // USER BIASA
            // =================================================

            return const BottomNav();
          },
        );
      },
    );
  }
}

// =====================================================================
// AUTH / FIRESTORE ERROR SCREEN
// =====================================================================

class AuthErrorScreen extends StatelessWidget {
  final String error;

  const AuthErrorScreen({
    super.key,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WarnaDesaPay.lightBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 72,
                  color: Colors.red,
                ),

                const SizedBox(height: 20),

                const Text(
                  'Terjadi kesalahan',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'DesaPay tidak dapat mengambil data akun.',
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SelectableText(
                    error,
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
