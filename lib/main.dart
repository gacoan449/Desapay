import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// === KONFIGURASI WARNA & FIREBASE DESAPAY ===
import 'config/warna.dart';
import 'firebase_options.dart';

// === LAYAR APLIKASI ===
import 'screens/splash/splash_screen.dart';
import 'screens/login/login_screen.dart';
import 'widgets/bottom_nav.dart';
import 'screens/admin/admin_dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Orientasi layar tetap Portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  try {
    // Muat variabel lingkungan (.env)
    await dotenv.load(fileName: ".env");

    // Inisialisasi Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    debugPrint("✅ DesaPay Sistem Siap! Firebase Terhubung");
  } catch (e) {
    debugPrint("⚠️ Inisialisasi Gagal: $e");
  }

  runApp(const DesaPayApp());
}

class DesaPayApp extends StatelessWidget {
  const DesaPayApp({super.key});

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
          background: WarnaDesaPay.lightBg,
        ),
        scaffoldBackgroundColor: WarnaDesaPay.lightBg,
        fontFamily: 'Inter',
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // ⏳ Loading / Cek sesi
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }

          // ❌ Belum Login → Buka Login
          if (!snapshot.hasData) {
            return const LoginScreen();
          }

          // ✅ Sudah Login → Cek Admin atau Pengguna
          final user = snapshot.data!;

          // 👑 ADMIN — Langsung buka Dashboard
          if (user.email != null &&
              user.email!.toLowerCase() == 'fikri.admin.desapay@gmail.com') {
            debugPrint("✅ Admin Login: ${user.email}");
            return const AdminDashboardScreen();
          }

          // 👤 PENGGUNA BIASA — Buka Halaman Utama
          debugPrint("✅ Pengguna Login: ${user.email}");
          return const BottomNav();
        },
      ),
    );
  }
}
