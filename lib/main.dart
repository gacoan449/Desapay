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

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    debugPrint(
      "✅ DesaPay Firebase berhasil terhubung.",
    );
  } catch (e) {
    debugPrint(
      "❌ Firebase initialization gagal: $e",
    );
  }

  // =========================================================
  // APP
  // =========================================================

  runApp(
    const DesaPayApp(),
  );
}

class DesaPayApp extends StatelessWidget {
  const DesaPayApp({
    super.key,
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

      // =======================================================
      // AUTH STATE
      // =======================================================

      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),

        builder: (context, snapshot) {
          // ===================================================
          // FIREBASE SEDANG CEK SESSION
          // ===================================================

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const SplashScreen();
          }

          // ===================================================
          // BELUM LOGIN
          // ===================================================

          final user = snapshot.data;

          if (user == null) {
            return const LoginScreen();
          }

          // ===================================================
          // CEK ROLE DI FIRESTORE
          // ===================================================

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get(),

            builder: (context, userSnap) {
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

              if (userSnap.hasData &&
                  userSnap.data!.exists) {
                final userData =
                    userSnap.data!.data()
                        as Map<String, dynamic>?;

                if (userData != null &&
                    userData['role'] == 'admin') {
                  return const AdminDashboardScreen();
                }
              }

              // =================================================
              // USER BIASA
              // =================================================

              return const BottomNav();
            },
          );
        },
      ),
    );
  }
}
