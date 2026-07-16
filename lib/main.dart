import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Memastikan semua import terarah ke repositori rill Anda sesuai dump data
import 'config/warna.dart';
import 'firebase_options.dart';
import 'screens/home/home_screen.dart';
import 'screens/welcome_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Memuat berkas konfigurasi env secara aman sebelum arsitektur Firebase aktif
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
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black87),
          titleTextStyle: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      // MENGEMBALIKAN GERBANG OTENTIKASI: Tidak langsung masuk ke Home secara ilegal
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Jika koneksi sedang memeriksa status session di device
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: WarnaDesaPay.primary),
              ),
            );
          }
          
          // Jika token user rill terdeteksi aktif, langsung arahkan ke Dashboard
          if (snapshot.hasData && snapshot.data != null) {
            return const HomeScreen();
          }
          
          // Jika tidak ada user yang login, wajib lempar ke Welcome Screen asli bawaan Anda
          return const WelcomeScreen();
        },
      ),
    );
  }
}
