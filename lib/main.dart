import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Import Komponen DesaPay (CTO Standard)
import 'config/warna.dart';
import 'firebase_options.dart';
import 'screens/splash/splash_screen.dart';
import 'widgets/bottom_nav.dart'; // Navigasi Utama (Logged In)
import 'screens/login/login_screen.dart'; // Gerbang Login

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load(fileName: ".env");
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Sistem DesaPay Inisialisasi Gagal: $e");
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
        ),
        scaffoldBackgroundColor: WarnaDesaPay.lightBg,
        fontFamily: 'Inter', // Pastikan font Inter sudah terdaftar di pubspec.yaml
      ),
      // GERBANG UTAMA: StreamBuilder untuk mendeteksi sesi aktif user
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Jika aplikasi masih inisialisasi sesi
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }
          
          // Jika user sudah login, langsung ke BottomNav (Dashboard)
          if (snapshot.hasData) {
            return const BottomNav();
          }
          
          // Jika user belum login, lempar ke Login
          return const LoginScreen();
        },
      ),
    );
  }
}
