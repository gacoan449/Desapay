import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'config/warna.dart';
import 'firebase_options.dart';
import 'screens/splash/splash_screen.dart'; // Panggil Splash Screen di sini

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load(fileName: ".env");
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Inisialisasi Dasar Sistem DesaPay Terhambat: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DesaPay',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: WarnaDesaPay.primary,
        scaffoldBackgroundColor: const Color(0xffF4F7FA),
      ),
      // GERBANG UTAMA DIKEMBALIKAN KE SPLASH SCREEN
      home: const SplashScreen(), 
    );
  }
}
