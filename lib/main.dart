import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
  // ENV
  // =========================================================

  try {
    await dotenv.load(
      fileName: ".env",
    );
  } catch (e) {
    debugPrint(
      "⚠️ .env tidak berhasil dimuat: $e",
    );
  }

  // =========================================================
  // FIREBASE
  // =========================================================

  try {
    await Firebase.initializeApp(
      options:
          DefaultFirebaseOptions.currentPlatform,
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

  // =========================================================
  // ADMIN EMAIL
  //
  // Tidak menggunakan password admin di APK.
  // Password tetap diverifikasi Firebase Authentication.
  // =========================================================

  static const String adminEmail =
      'fikri.admin.desapay@gmail.com';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DesaPay',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,

        colorScheme:
            ColorScheme.fromSeed(
          seedColor:
              WarnaDesaPay.primary,
          primary:
              WarnaDesaPay.primary,
          onPrimary:
              Colors.white,
          secondary:
              WarnaDesaPay.secondary,
          surface:
              Colors.white,
        ),

        scaffoldBackgroundColor:
            WarnaDesaPay.lightBg,

        fontFamily:
            'Inter',

        appBarTheme:
            const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),

      // =======================================================
      // AUTH STATE
      // =======================================================

      home: StreamBuilder<User?>(
        stream:
            FirebaseAuth.instance
                .authStateChanges(),

        builder:
            (context, snapshot) {
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

          final user =
              snapshot.data;

          if (user == null) {
            return const LoginScreen();
          }

          // ===================================================
          // ADMIN
          // ===================================================

          final email =
              user.email
                  ?.trim()
                  .toLowerCase();

          if (email ==
              adminEmail.toLowerCase()) {
            debugPrint(
              "✅ Admin terdeteksi: $email",
            );

            return const AdminDashboardScreen();
          }

          // ===================================================
          // USER BIASA
          // ===================================================

          debugPrint(
            "✅ User terdeteksi: $email",
          );

          return const BottomNav();
        },
      ),
    );
  }
}
